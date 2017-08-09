public class CodeClimatePOC {
    
	public class ProcessAccounts(){}
	
		list<account> acList = [select id,Name from account];
		
		for(account a: acList){
			list<contact> cList = [select id from contact where accountId =: a.id];
		}
	
	}
	
	
	public class GetContacts(){}
	
		list<account> acList = [select id,Name from account];
		
		for(account a: acList){
			list<contact> cList = [select id from contact where accountId =: a.id];
		}
	
	}
	
}