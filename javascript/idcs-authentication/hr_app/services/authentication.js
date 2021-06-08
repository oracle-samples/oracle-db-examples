const passport = require('passport');
const expressSession = require('express-session');
const {OIDCStrategy, IdcsAuthenticationManager} = require('passport-idcs');
const config = require('../config/authentication.js');

const authMgr = new IdcsAuthenticationManager(config.idcs.classOpts);

function initWebServer(app) {
  app.use(expressSession(config.sessionOpts));

  passport.serializeUser(function(user, done) {
    done(null, user);
  });

  passport.deserializeUser(function(obj, done) {
    done(null, obj);
  });

  passport.use(new OIDCStrategy(config.idcs.classOpts, (idToken, tenant, user, done) => {
    done(null, user);
  }));

  app.use(passport.initialize());
  app.use(passport.session());

  app.get('/user', user);

  app.get('/login', login);

  app.get('/callback',
    callback,
    passport.authenticate(config.idcs.strategyName),
    (req, res, next) => {
      const redirect = req.session.oauth2return || '/';

      delete req.session.oauth2return;

      res.redirect(redirect);
    }
  );

  app.get('/logout', logout);
}

module.exports.initWebServer = initWebServer;

function user(req, res, next) {
  if (req.isAuthenticated()) {
    let response = Object.assign({authenticated: true}, req.user);
    res.json(response);
  } else {
    res.json({authenticated: false});
  }
}

async function login(req, res, next) {
  try {
    const authZurl = await authMgr.getAuthorizationCodeUrl(
      config.idcs.loginRedirectUrl, 
      config.idcs.authCodeScope, 
      null, 
      config.idcs.authResponseType
    );

    res.redirect(authZurl);
  } catch (err) {
    next(err);
  }
}

async function callback(req, res, next) {
  try {
    const authZcode = req.query.code;
    const tokens = await authMgr.authorizationCode(authZcode);

    // Storing id_token in the session (server side) for logout purposes.
    req.session.id_token = tokens.id_token;

    // Adding a request header that is required by the IDCS strategy.
    req.headers[config.idcs.authHeaderName] = tokens.access_token;

    next(); // Forwarding to passport.authenticate
  } catch (err) {
    next(err);
  }
}

async function logout(req, res, next) {
  try {
    const logoutUrl = await authMgr.getLogoutUrl(config.idcs.logoutRedirectUrl, null, req.session.id_token);

    req.logout();

    req.session.destroy(err => {
      if (err) {
        next(err);
        return;
      }

      res.redirect(logoutUrl);
    });    
  } catch (err) {
    next(err);
  }
}

function ensureAuthenticated(group) {
  return function(req, res, next) {
    if (req.isAuthenticated()) {
      if (group === undefined) {
        next();
      } else if (typeof group === 'string') {
        for (let groupIdx = 0; groupIdx < req.user.groups.length; groupIdx += 1) {
          if (req.user.groups[groupIdx].name === group) {
            next();
            return;
          }
        }

        res.status(401).send({message: 'Unauthorized'});
      } else {
        next(new Error('\'group\' must be undefined or a string'));
      }
    } else {
      req.session.oauth2return = req.originalUrl;
      res.redirect('/login');
    }
  }
}

module.exports.ensureAuthenticated = ensureAuthenticated;
