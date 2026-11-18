# server/ 自建短信后端模板

给「第 7 步」用的最小后端骨架：短信验证码发送 + 校验 + 签发 JWT。

## 运行

```bash
cd server
npm install express jsonwebtoken
JWT_SECRET=一段随机长字符串 node server.js
```

默认监听 `http://127.0.0.1:3000`。

## 上线前的硬性要求（缺一不可）

1. **域名 + HTTPS**：国内服务器域名需完成 ICP 备案。
2. **阿里云短信**：个人开发者可申请「签名」（如 App 名）和
   「验证码模板」，等审核通过后按 server.js 里的 TODO 接入 SDK：
   [SendSms API 文档](https://help.aliyun.com/zh/sms/developer-reference/api-dysmsapi-2017-05-25-sendsms)
3. **存储**：模板用内存 Map 存验证码，重启即丢；生产必须换 Redis，
   并按 IP + 手机号双维度限流（发送接口和校验接口都要限）。
4. **密钥管理**：JWT_SECRET、阿里云 AccessKey 放环境变量或密钥服务，
   不进代码仓库。

## 安全清单

- 验证码只存哈希（模板已做），5 分钟过期，错 5 次作废；
- 同一手机号 60 秒内只能发一次（模板已做）；
- 验证码永不写日志；
- 登录态 token 用 JWT 签出，App 端存 Keychain。
