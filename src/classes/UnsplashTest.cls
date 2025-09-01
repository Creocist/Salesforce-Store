@IsTest
private class UnsplashTest {

	@IsTest
	static void testFakeUrl() {
		UnsplashService.fakeUrl = 'https://test.com/fake.jpg';
		Test.startTest();
		String url = UnsplashService.getImageUrl('Apple');
		Test.stopTest();

		System.assertEquals('https://test.com/fake.jpg', url);
		UnsplashService.fakeUrl = null;
	}

	@IsTest
	static void testHttpCalloutSuccess() {
		Test.setMock(HttpCalloutMock.class, new UnsplashMock());
		UnsplashService.fakeUrl = null;

		Test.startTest();
		String url = UnsplashService.getImageUrl('Banana');
		Test.stopTest();

		System.assertEquals('https://mocked.com/photo.jpg', url);
	}

	@IsTest
	static void testHttpCalloutEmpty() {
		Test.setMock(HttpCalloutMock.class, new UnsplashEmptyMock());
		UnsplashService.fakeUrl = null;

		Test.startTest();
		String url = UnsplashService.getImageUrl('Orange');
		Test.stopTest();

		System.assertEquals(null, url);
	}
	private class UnsplashMock implements HttpCalloutMock {
		public  HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setBody('{"results":[{"urls":{"regular":"https://mocked.com/photo.jpg"}}]}');
			return res;
		}
	}
	private class UnsplashEmptyMock implements HttpCalloutMock {
		public  HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setBody('{"results":[]}');
			return res;
		}
	}
}
