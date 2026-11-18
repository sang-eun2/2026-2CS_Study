<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ page import="java.sql.*" %>
<%
	Connection conn = null;
	
	String driver = "oracle.jdbc.driver.OracleDriver";
	String url = "jdbc:oracle:thin:@localhost:1521:orcl";
	
	Boolean connect = false;
	
	try{
		Class.forName(driver);
		conn = DriverManager.getConnection(url, "YOUR_DB_USER", "YOUR_DB_PASSWORD");
		connect = true;
		conn.close();
	}catch(Exception e) {
		connect = false;
		out.print(e);
	}
%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=EUC-KR">
<title>Insert title here</title>
</head>
<body>
<%
	if(connect == true) {
		out.print("연결되었습니다.");
	}else{
		out.print("연결에 실패하였습니다.");
	}
%>
</body>
</html>