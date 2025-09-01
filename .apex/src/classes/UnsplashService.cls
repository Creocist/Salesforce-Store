public with sharing class UnsplashService {

	private static final String ACCESS_KEY = '9anCTOn-wbjCAH6MDeRhbnrN70lOBH0fVCfuBpZpORk';
	@TestVisible
	private static String fakeUrl = null;

	public static String getImageUrl(String itemName) {
		if (Test.isRunningTest() && fakeUrl != null) {
			return fakeUrl;
		}
		try {
			Http http = new Http();
			HttpRequest req = new HttpRequest();
			req.setEndpoint('https://api.unsplash.com/search/photos?query=' + EncodingUtil.urlEncode(itemName, 'UTF-8'));
			req.setMethod('GET');
			req.setHeader('Authorization', 'Client-ID ' + ACCESS_KEY);

			HttpResponse res = http.send(req);
			if (res.getStatusCode() == 200) {
				Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
				List<Object> photos = (List<Object>) result.get('results');

				if (!photos.isEmpty()) {
					Map<String, Object> firstPhoto = (Map<String, Object>) photos[0];
					Map<String, Object> urls = (Map<String, Object>) firstPhoto.get('urls');
					return (String) urls.get('regular');
				}
			}
		} catch (Exception e) {
			System.debug('Unsplash error: ' + e.getMessage());
		}
		return null;
	}
}
