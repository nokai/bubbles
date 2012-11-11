#include <WinSock2.h>  
#include <cstdio>  
#include <iostream>
#include <set>
#include <string>
#include <cstdlib>
#include <ctime>

#pragma comment(lib, "ws2_32.lib") 

using namespace std; 

const char MyIDFormat[]="YZM-%d";
const int MAX_BUF_LEN=1024;
const int PORT=3307;

int main(int argc, char* argv[])  
{   

	char MyID[MAX_BUF_LEN];
	sprintf(MyID,MyIDFormat,time(NULL));
	
	printf("I'M %s\n",MyID);
	
    WSADATA wsaData;   
    // 启动socket api  
    WSAStartup( MAKEWORD( 2, 2 ), &wsaData );  
    
	//Socket
	SOCKET socket_fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP); 

	
	
	SOCKADDR_IN sin,sin_from;
	int nAddrLen = sizeof(SOCKADDR); 
	
	//广播地址
    sin.sin_family = AF_INET;  
    sin.sin_port = htons(PORT);  
    sin.sin_addr.s_addr = 0;  
	
	//接受地址
    sin_from.sin_family = AF_INET;  
    sin_from.sin_port = htons(PORT);  
    sin_from.sin_addr.s_addr = INADDR_BROADCAST;  
	
	//设置该套接字为广播类型  
    bool bOpt = true;  
    setsockopt(socket_fd, SOL_SOCKET, SO_BROADCAST, (char*)&bOpt, sizeof(bOpt));

	
	//绑定
	bind(socket_fd, (SOCKADDR*)&sin, nAddrLen ); 
	
	//新加入一个伙伴
	char buff[MAX_BUF_LEN];
	sprintf(buff,"H%s",MyID);
	sendto(socket_fd, buff, strlen(buff), 0, (SOCKADDR*)&sin_from, nAddrLen);
	printf("ERROR %d\n",WSAGetLastError());
	bool EXIT=false;
	while (!EXIT)
	{
		buff[0]='\0';
		//监听网络上的消息
		int nSize = recvfrom(socket_fd, buff, MAX_BUF_LEN, 0, (SOCKADDR*)&sin_from, &nAddrLen);  
		printf("%s:%d\t%d:%s\n", inet_ntoa(sin_from.sin_addr),ntohs(sin_from.sin_port),nSize,buff);
		if (nSize>1 && (buff[0]=='H' || buff[0]=='I') )
		{	//发现一个新伙伴 ， 加入列表
		
			//List.add(string(buff+1));
			printf("New Peer %s\n",buff+1);
			
			//对于新伙伴，介绍一下自己
			if (buff[0]=='H' && strcmp(buff+1,MyID) !=0 )
			{
				sprintf(buff,"I%s",MyID);
				sendto(socket_fd, buff, strlen(buff), 0, (SOCKADDR*)&sin_from, nAddrLen);
			}
		}
		if (nSize>1 && buff[0]=='B')
		{	//伙伴退出 ，删除列表
			//List.del(string(buff+1));
			printf("Del Peer %s\n",buff+1);
		}
		
		//DEBUG
		if (nSize>1 && buff[0]=='E' && strcmp(buff+1,MyID)==0)
		{	//获得一个退出命令
			EXIT=true;
		}
		Sleep(300);
	}
	
	sprintf(buff,"B%s",MyID);
	sendto(socket_fd, buff, strlen(buff), 0, (SOCKADDR*)&sin, nAddrLen);

	exit(0);
}
