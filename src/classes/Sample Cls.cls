public class CodeClimatePOC {
    
	public class ProcessAccounts(){
	
		list<account> acList = [select id,Name from account];
		
		for(account a: acList){
			list<contact> cList = [select id from contact where accountId =: a.id];
		}
	
	}
	

	public class PPPPPP(){
	
		list<account> acList = [select id,Name from account];
		
		for(account a: acList){
			contact c = new contact();
			c.lastname = 'SASAS S';
			insert c;
		}
    
	}


	public class hardCodeIdContacts(){
	
		list<account> acList = [select id,Name from account];
		
		for(account a: acList){
			contact c = new contact();
			c.accountId = 'SA213W1211dsadsw12312312';
			insert c;
		}
    
	}			
	
}