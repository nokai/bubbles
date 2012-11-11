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
    // ����socket api  
    WSAStartup( MAKEWORD( 2, 2 ), &wsaData );  
    
	//Socket
	SOCKET socket_fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP); 

	
	
	SOCKADDR_IN sin,sin_from;
	int nAddrLen = sizeof(SOCKADDR); 
	
	//�㲥��ַ
    sin.sin_family = AF_INET;  
    sin.sin_port = htons(PORT);  
    sin.sin_addr.s_addr = 0;  
	
	//���ܵ�ַ
    sin_from.sin_family = AF_INET;  
    sin_from.sin_port = htons(PORT);  
    sin_from.sin_addr.s_addr = INADDR_BROADCAST;  
	
	//���ø��׽���Ϊ�㲥����  
    bool bOpt = true;  
    setsockopt(socket_fd, SOL_SOCKET, SO_BROADCAST, (char*)&bOpt, sizeof(bOpt));

	
	//��
	bind(socket_fd, (SOCKADDR*)&sin, nAddrLen ); 
	
	//�¼���һ�����
	char buff[MAX_BUF_LEN];
	sprintf(buff,"H%s",MyID);
	sendto(socket_fd, buff, strlen(buff), 0, (SOCKADDR*)&sin_from, nAddrLen);
	printf("ERROR %d\n",WSAGetLastError());
	bool EXIT=false;
	while (!EXIT)
	{
		buff[0]='\0';
		//���������ϵ���Ϣ
		int nSize = recvfrom(socket_fd, buff, MAX_BUF_LEN, 0, (SOCKADDR*)&sin_from, &nAddrLen);  
		printf("%s:%d\t%d:%s\n", inet_ntoa(sin_from.sin_addr),ntohs(sin_from.sin_port),nSize,buff);
		if (nSize>1 && (buff[0]=='H' || buff[0]=='I') )
		{	//����һ���»�� �� �����б�
		
			//List.add(string(buff+1));
			printf("New Peer %s\n",buff+1);
			
			//�����»�飬����һ���Լ�
			if (buff[0]=='H' && strcmp(buff+1,MyID) !=0 )
			{
				sprintf(buff,"I%s",MyID);
				sendto(socket_fd, buff, strlen(buff), 0, (SOCKADDR*)&sin_from, nAddrLen);
			}
		}
		if (nSize>1 && buff[0]=='B')
		{	//����˳� ��ɾ���б�
			//List.del(string(buff+1));
			printf("Del Peer %s\n",buff+1);
		}
		
		//DEBUG
		if (nSize>1 && buff[0]=='E' && strcmp(buff+1,MyID)==0)
		{	//���һ���˳�����
			EXIT=true;
		}
		Sleep(300);
	}
	
	sprintf(buff,"B%s",MyID);
	sendto(socket_fd, buff, strlen(buff), 0, (SOCKADDR*)&sin, nAddrLen);

	exit(0);
}
