public class CodeClimatePOC {
    
	public class FindRlatedContacts(){}
	
		list<account> acList = [select id,Name from account];
		
		for(account a: acList){
			list<contact> cList = [select id from contact where accountId =: a.id];
		}
	
	}
	
	
}