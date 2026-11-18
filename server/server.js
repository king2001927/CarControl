// 自建短信验证码登录后端模板（Node.js + Express）
//
// 提供两个接口：
//   POST /api/sms/send     { phone }                  → 发送验证码，返回 { verificationId }
//   POST /api/sms/verify   { phone, code, verificationId } → 校验，返回 { token }
//
// 上线前必须完成（缺一不可）：
//   1. 域名 + HTTPS（国内服务器域名需 ICP 备案）；
//   2. 阿里云短信：申请签名（个人可申请）和验证码模板，等审核通过；
//   3. 把 TODO 里的 SendSms 调用补上（阿里云 SDK，见
//      https://help.aliyun.com/zh/sms/developer-reference/api-dysmsapi-2017-05-25-sendsms ）；
//   4. 验证码存储换成 Redis 等共享存储，并给发送接口做频率限制（IP + 手机号维度）；
//   5. 验证码永不落日志，校验失败次数也要限制。
//
// 运行：npm install express jsonwebtoken && node server.js

const crypto = require('crypto');
const express = require('express');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

// ============ 配置（按需修改） ============
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || '请替换成随机长字符串';
const TOKEN_TTL_SECONDS = 30 * 24 * 3600; // 登录态 30 天
const CODE_TTL_MS = 5 * 60 * 1000;        // 验证码 5 分钟有效
const SEND_INTERVAL_MS = 60 * 1000;       // 同一手机号 60 秒内只能发一次

// 演示用的内存存储：生产环境必须换成 Redis
const pendingCodes = new Map(); // phone -> { code, expiresAt, lastSentAt, tries }

// ============ 工具 ============
function hash(phone, code) {
  // 不存明文验证码，只存摘要
  return crypto.createHash('sha256').update(`${phone}:${code}:${JWT_SECRET}`).digest('hex');
}

function isValidPhone(phone) {
  return typeof phone === 'string' && /^1\d{10}$/.test(phone);
}

// TODO: 接入阿里云短信。个人开发者请先在控制台申请签名和模板，
// 模板内容形如「您的验证码为 ${code}，5 分钟内有效，请勿泄露」。
async function sendSmsViaAliyun(phone, code) {
  // const Dysmsapi = require('@alicloud/dysmsapi20170525');
  // const client = new Dysmsapi.default(new Dysmsapi.Config({
  //   accessKeyId: process.env.ALIYUN_AK,
  //   accessKeySecret: process.env.ALIYUN_SK,
  //   endpoint: 'dysmsapi.aliyuncs.com',
  // }));
  // await client.sendSms(new Dysmsapi.SendSmsRequest({
  //   phoneNumbers: phone,
  //   signName: '你的签名',
  //   templateCode: '你的模板CODE',
  //   templateParam: JSON.stringify({ code }),
  // }));
  console.log(`[演示] 未接入短信服务，${phone} 的验证码是 ${code}`);
}

// ============ 接口 ============

// 发送验证码
app.post('/api/sms/send', async (req, res) => {
  const { phone } = req.body || {};
  if (!isValidPhone(phone)) {
    return res.status(400).json({ error: '手机号格式不正确' });
  }
  const existing = pendingCodes.get(phone);
  const now = Date.now();
  if (existing && now - existing.lastSentAt < SEND_INTERVAL_MS) {
    return res.status(429).json({ error: '发送太频繁，请稍后再试' });
  }

  const code = String(crypto.randomInt(100000, 1000000)); // 6 位
  pendingCodes.set(phone, {
    digest: hash(phone, code),
    expiresAt: now + CODE_TTL_MS,
    lastSentAt: now,
    tries: 0,
  });

  try {
    await sendSmsViaAliyun(phone, code);
  } catch (e) {
    console.error('短信发送失败', e);
    return res.status(502).json({ error: '短信服务暂时不可用' });
  }

  // verificationId 只是会话标识，不含验证码本身
  const verificationId = crypto.randomUUID();
  const entry = pendingCodes.get(phone);
  entry.verificationId = verificationId;
  res.json({ verificationId });
});

// 校验验证码并签发登录态
app.post('/api/sms/verify', (req, res) => {
  const { phone, code, verificationId } = req.body || {};
  if (!isValidPhone(phone) || typeof code !== 'string' || !/^\d{6}$/.test(code)) {
    return res.status(400).json({ error: '参数不正确' });
  }
  const entry = pendingCodes.get(phone);
  if (!entry || entry.verificationId !== verificationId) {
    return res.status(400).json({ error: '请先获取验证码' });
  }
  if (Date.now() > entry.expiresAt) {
    pendingCodes.delete(phone);
    return res.status(400).json({ error: '验证码已过期，请重新获取' });
  }
  if (entry.tries >= 5) {
    pendingCodes.delete(phone);
    return res.status(429).json({ error: '错误次数过多，请重新获取验证码' });
  }
  if (entry.digest !== hash(phone, code)) {
    entry.tries += 1;
    return res.status(400).json({ error: '验证码不正确' });
  }

  pendingCodes.delete(phone);
  const token = jwt.sign({ phone }, JWT_SECRET, { expiresIn: TOKEN_TTL_SECONDS });
  res.json({ token });
});

app.listen(PORT, () => {
  console.log(`SMS auth server listening on http://127.0.0.1:${PORT}`);
});
