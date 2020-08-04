import 'package:flutter/material.dart';
import 'package:flutter_todo_list/model/todo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  // 할 일 문자열 조작을 위한 컨트롤러
  var _todoController = TextEditingController();

  @override
  void dispose() {
    _todoController.dispose(); // 사용이 끝나면 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('남은 할 일'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _todoController,
                  ),
                ),
                RaisedButton(
                  child: Text('추가'),
                  onPressed: () => _addTodo(Todo(_todoController.text)),
                ),
              ],
            ),
            StreamBuilder<QuerySnapshot>( // 스트림 값이 변경될 때마다 빌드 호출
              stream: Firestore.instance.collection('todo').snapshots(), // 컬렉션에 있는 모든 문서를 스트림으로 얻음
              builder: (context, snapshot) { // 화면에 그려질 UI를 반환
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                final documents = snapshot.data.documents; // 모든 문서를 얻음
                return Expanded(
                  child: ListView(
                    children: documents.map((doc) => _buildItemWidget(doc)).toList(),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }
  
  // 할 일 추가 메서드
  void _addTodo(Todo todo) {
    Firestore.instance
        .collection('todo')
        .add({'title': todo.title, 'isDone': todo.isDone});
    _todoController.text = '';
  }

  // 할 일 삭제 메서드
  void _deleteTodo(DocumentSnapshot doc) {
    // DocumentSnapshot에서 특정 문서의 id를 얻어서 삭제
    Firestore.instance.collection('todo').document(doc.documentID).delete();
  }

  // 할 일 완료/미완료 메서드
  void _toggleTodo(DocumentSnapshot doc) {
    // DocumentSnapshot에서 특정 문서의 id를 얻어서 업데이트
    Firestore.instance.collection('todo').document(doc.documentID).updateData({
      'isDone': !doc['isDone'],
    });
  }

  // 할 일 객체를 ListTile 형태로 변경하는 메서드
  Widget _buildItemWidget(DocumentSnapshot doc) { // FireStore 문서는 DocumentSnapshot 클래스의 인스턴스임
    final todo = Todo(doc['title'], isDone: doc['isDone']);
    return ListTile(
      onTap: () => _toggleTodo(doc),
      title: Text(
        todo.title,
        style: todo.isDone
                ? TextStyle(
                    decoration: TextDecoration.lineThrough, // 취소선
                    fontStyle: FontStyle.italic, // 이탤릭체
                  )
                : null,
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_forever),
        onPressed: () => _deleteTodo(doc),
      ),
    );
  }
}
