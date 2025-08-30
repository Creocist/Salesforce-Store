public with sharing class ItemController {

    @AuraEnabled(cacheable=true)
    public static List<Item__c> searchItems(
            List<String> types,
            List<String> families,
            String searchKey,
            Integer limitSize,
            Integer offsetSize
    ) {
        // sane defaults
        if (limitSize == null || limitSize <= 0 || limitSize > 2000) limitSize = 50;
        if (offsetSize == null || offsetSize < 0) offsetSize = 0;

        String base = 'SELECT Id, Name, Description__c, Price__c, Type__c, Family__c, Image__c FROM Item__c';
        List<String> whereParts = new List<String>();

        if (types != null && !types.isEmpty()) {
            whereParts.add('Type__c IN :types');
        }
        if (families != null && !families.isEmpty()) {
            whereParts.add('Family__c IN :families');
        }
        String likeKey;
        if (String.isNotBlank(searchKey)) {
            likeKey = '%' + searchKey + '%';
            whereParts.add('(Name LIKE :likeKey OR Description__c LIKE :likeKey)');
        }

        String soql = base + (whereParts.isEmpty() ? '' : ' WHERE ' + String.join(whereParts, ' AND '))
                + ' ORDER BY Name LIMIT :limitSize OFFSET :offsetSize';

        return Database.query(soql);
    }
}