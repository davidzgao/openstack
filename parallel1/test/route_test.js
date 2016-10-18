var request = require('supertest'),
    app = require('../app'),
    assert = require("assert");

describe('Index', function() {
  describe('POST', function() {
    it('should fail bad when post', function(done) {
      request(app)
        .post('/')
        .send({'test': 'test'})
        .expect(500);
        done();
    });
  });

  describe('GET', function() {
    it('should success when get', function(done) {
      request(app)
        .get('/')
        .expect(200);
        done();
    });
  });
});
