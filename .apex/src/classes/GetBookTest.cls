/**
 * Created by admin on 29.08.2025.
 */

@IsTest
private class GetBookTest {
    @IsTest
    static void testBehavior() {
        Item__c Book = new Item__c(Name = 'Harry Potter', Price__c = 20.55, Description__c = 'Story about a boy who survived', Type__c = 'Fiction', Family__c = 'Paperback');
        insert Book;

        Test.startTest();
            System.debug(Book);
        Test.stopTest();
    }
}