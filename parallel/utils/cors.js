/*
* This module is used to add some headers to response,
* that allow cross site request for allowed host.
*/
module.exports = function(req, res, next) {
  // NOTE(ZhengYue): Replace the double quota to single quota
  if(allowHosts.indexOf(req.headers.origin) != -1) {
    res.header("Access-Control-Allow-Origin", req.headers.origin);
  }
  res.header("Access-Control-Allow-Headers",
    "Content-Type, Content-Length, Authorization, Accept, X-Requested-With, X-Image-Meta, X-platform");
  res.header('Access-Control-Allow-Credentials', true);
  res.header("Access-Control-Allow-Methods", "PUT, POST, GET, DELETE, OPTIONS");
  return next();
}
