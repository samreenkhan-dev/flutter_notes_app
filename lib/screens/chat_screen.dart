import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final msgController=TextEditingController();
  final supabase=Supabase.instance.client;
  RealtimeChannel? channel;
  List<Map<String,dynamic>> messages=[];

  listenBroadcast(){
    channel=supabase.channel('room1',opts: RealtimeChannelConfig(self: true));
    channel?.onBroadcast(event: 'event1', callback: (payload){
      print('Payload:$payload');
      setState(() {
        messages.add(payload);
      });

    });
    channel?.onPresenceSync((payload) {
      print('Payload:$payload');
    },);
    channel?.onPresenceLeave((payload) {

    },);
    channel?.subscribe();
  }

  sendMessage() async{
    String text=msgController.text;
    msgController.clear();

    ChannelResponse? response=await channel?.sendBroadcastMessage(
        event: 'event1', payload: {
          'text':text,
          'user_id':supabase.auth.currentUser?.id
    });
    print('Message status:${response?.name}');

  }


  void initState(){
    listenBroadcast();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat App'),leading: Icon(Icons.chat,color:Colors.green),),
      body: Column(
        children:
        [Expanded(child: ListView(
          children: [
            for(var msg in messages)
              Align(
                alignment: msg['user_id']==supabase.auth.currentUser?.id?
                    AlignmentGeometry.centerRight:AlignmentGeometry.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 300,
                  ),
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:msg['user_id']==supabase.auth.currentUser?.id?
                    Colors.blue:Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Text(msg['text']),
                ),
              )

          ],
        )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 10),
            child: Row(children: [
              Expanded(child: TextField(
                controller: msgController,
                decoration: InputDecoration(
                  hintText: 'Type your message',
                ),
              )),
              IconButton(onPressed: (){
                sendMessage();

              }, icon: Icon(Icons.send,color:Colors.blue))
            ],),
          )

        ]
        ,),
    );
  }
}
