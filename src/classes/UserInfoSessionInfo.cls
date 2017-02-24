@RestResource(urlMapping='/UserInfoSessionInfo/*')
global with sharing class UserInfoSessionInfo {

@HttpGet   
  global static String getCurrentSessionInfo() {

           
     return userInfo.getSessionId();
  }
}