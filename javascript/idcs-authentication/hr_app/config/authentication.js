module.exports = {
  idcs: {
    classOpts: {
      ClientTenant: process.env.IDCS_CLIENT_TENANT,
      ClientId: process.env.IDCS_CLIENT_ID,
      ClientSecret: process.env.IDCS_CLIENT_SECRET,
      IDCSHost: `https://${process.env.IDCS_CLIENT_TENANT}.identity.oraclecloud.com`,
      AudienceServiceUrl: `https://${process.env.IDCS_CLIENT_TENANT}.identity.oraclecloud.com`,
      TokenIssuer: 'https://identity.oraclecloud.com/',
      LogLevel: 'warn'
    },
    strategyName: 'IDCSOIDC',
    authHeaderName: 'idcs_user_assertion',
    authCodeScope: 'urn:opc:idm:t.user.me openid',
    authResponseType: 'code',
    loginRedirectUrl: 'http://localhost:3000/callback',
    logoutRedirectUrl: 'http://localhost:3000'
  },
  sessionOpts: {
    secret: '?e4TpH,),Rox9k8LBKH7',
    resave: false,
    saveUninitialized: false,
    cookie: {
      maxAge: 1000 * 60 * 60 * 8 // 1000 ms * 60 s * 60 m * 8 h = eight hours in ms
    }
  }
};
