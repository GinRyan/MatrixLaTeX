import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

void main(List<String> args) {
  runApp(MaterialApp(
    title: '矩阵LaTeX代码生成器',
    theme: ThemeData(
      primarySwatch: Colors.green,
    ),
    home: Scaffold(
      body: MainFrameWidget(),
      appBar: AppBar(
        title: Text("矩阵LaTeX生成器"),
      ),
    ),
  ));
}

/// 需要输入的字段有：
///
/// m x n 矩阵的“m”, “n”
/// 然后生成相应大小的表格输入框，
/// 选项：矩阵括号、行列式括号
///
/// 输出LaTeX文本
///

class MainFrameWidget extends StatefulWidget {
  @override
  MainFrameWidgetState createState() {
    return MainFrameWidgetState();
  }
}

List<List<String>> _table = [];
bool isDetermine = false;
bool asBlock = false;

class MainFrameWidgetState extends State<MainFrameWidget> {
  ValueChanged<String> onRowInput;
  ValueChanged<String> onColumnInput;
  int row = 0;
  int column = 0;

  int rowReadOnly = 0;
  int columnReadOnly = 0;

  List<List<TextEditingController>> _textEditingController = [];
  TextEditingController outputEditingController = TextEditingController();

  final String matrixLeft = "\\left [\\begin{matrix} ";
  final String matrixRight = " \\end{matrix}\\right]";
  final String determineLeft = "\\left |\\begin{matrix} ";
  final String determineRight = " \\end{matrix}\\right|";
  final String andChar = " & ";
  final String endline = "\\\\";

  @override
  void initState() {
    super.initState();
    onRowInput = (String text) {
      try {
        row = int.parse(text);

        if (row < 0) {
          row = 0;
          var snk = SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('不能小于0'),
          );
          Scaffold.of(context).showSnackBar(snk);
        }
      } catch (e) {
        var snk = SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('输入行必须是整数类型'),
        );
        Scaffold.of(context).showSnackBar(snk);
      }
    };

    onColumnInput = (String text) {
      try {
        column = int.parse(text);

        if (column < 0) {
          column = 0;
          var snk = SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('不能小于0'),
          );
          Scaffold.of(context).showSnackBar(snk);
        }
      } catch (e) {
        var snk = SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('输入列必须是整数类型'),
        );
        Scaffold.of(context).showSnackBar(snk);
      }
    };
  }

  @override
  void dispose() {
    super.dispose();
    outputEditingController.dispose();
    for (var i = 0; i < _textEditingController.length; i++) {
      for (var j = 0; j < _textEditingController[i].length; j++) {
        _textEditingController[i][j].dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _textEditingController = [];

    List<Widget> _columnLines = [];

    //print("Update table as ($rowReadOnly,$columnReadOnly)");
    for (var i = 0; i < rowReadOnly; i++) {
      if (_table.length < rowReadOnly) {
        _table.add([]);
      }

      if (_textEditingController.length < rowReadOnly) {
        _textEditingController.add([]);
      }

      List<Widget> rowLines = [];
      for (var j = 0; j < columnReadOnly; j++) {
        String item = "";
        if (_table[i].length < columnReadOnly) {
          _table[i].add(item);
        }

        if (_textEditingController[i].length < columnReadOnly) {
          _textEditingController[i].add(TextEditingController());
        }

        rowLines.add(Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(),
          child: Container(
            child: SizedBox(
              height: 50,
              width: 100,
              child: TextFormField(
                controller: _textEditingController[i][j],
                keyboardType: TextInputType.number,
                onChanged: (String text) {
                  _table[i][j] = text;
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "${i + 1} 行 ${j + 1} 列"),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 0),
          ),
        ));
      }

      _columnLines.add(Row(
        children: rowLines,
      ));
    }
    //print(_table);

    List<Widget> line = [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("行数列数："),
          Container(
            child: SizedBox(
              height: 45,
              width: 45,
              child: TextFormField(
                keyboardType: TextInputType.number,
                onChanged: onRowInput,
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: '行'),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8),
          ),
          Container(
            child: SizedBox(
              height: 45,
              width: 45,
              child: TextFormField(
                keyboardType: TextInputType.number,
                onChanged: onColumnInput,
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: '列'),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8),
          ),
          Container(
            child: SizedBox(
              height: 45,
              width: 120,
              child: RaisedButton(
                color: Colors.green.shade300,
                child: Text(
                  "生成输入表格",
                ),
                onPressed: () {
                  setState(() {
                    rowReadOnly = row;
                    columnReadOnly = column;
                  });
                },
              ),
            ),
            padding: EdgeInsets.all(12),
          ),
        ],
      ),
    ];

    line.add(Prefs());

    line.addAll(_columnLines);

    line.add(
      GenerateResultWidget(
          determineLeft: determineLeft,
          matrixLeft: matrixLeft,
          determineRight: determineRight,
          matrixRight: matrixRight,
          andChar: andChar,
          endline: endline,
          outputEditingController: outputEditingController),
    );

    var mainFrame = FittedBox(
      child: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          children: line,
        ),
      ),
    );
    return mainFrame;
  }
}

class GenerateResultWidget extends StatefulWidget {
  const GenerateResultWidget({
    Key key,
    @required this.determineLeft,
    @required this.matrixLeft,
    @required this.determineRight,
    @required this.matrixRight,
    @required this.andChar,
    @required this.endline,
    @required this.outputEditingController,
  }) : super(key: key);

  final String determineLeft;
  final String matrixLeft;
  final String determineRight;
  final String matrixRight;
  final String andChar;
  final String endline;
  final TextEditingController outputEditingController;

  @override
  _GenerateResultWidgetState createState() => _GenerateResultWidgetState();
}

class _GenerateResultWidgetState extends State<GenerateResultWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            height: 40,
            width: 100,
            child: RaisedButton(
                color: Colors.green.shade300,
                child: Text(
                  "生成LaTeX",
                ),
                onPressed: () {
                  String start =
                      isDetermine ? widget.determineLeft : widget.matrixLeft;
                  String end =
                      isDetermine ? widget.determineRight : widget.matrixRight;

                  String arrayLaTex = start;

                  for (var i = 0; i < _table.length; i++) {
                    for (var j = 0; j < _table[i].length; j++) {
                      arrayLaTex += _table[i][j];
                      if (j + 1 < _table[i].length) {
                        arrayLaTex += widget.andChar;
                      }
                    }
                    arrayLaTex += widget.endline + "\n";
                  }
                  arrayLaTex += end;

                  if (asBlock) {
                    arrayLaTex = "\$\$$arrayLaTex\$\$";
                  }
                  setState(() {
                    print("Matrix: $arrayLaTex");
                    widget.outputEditingController.text = "$arrayLaTex";

                    //outputEditingController.value.copyWith(text: "$_table");
                  });
                }),
          ),
        ),
        Container(
          child: SizedBox(
            height: 300,
            width: 300,
            child: TextField(
              controller: widget.outputEditingController,
              enableInteractiveSelection: true,
              readOnly: false,
              decoration: InputDecoration(
                  border: OutlineInputBorder(), labelText: 'LaTeX代码，按Ctrl+C复制'),
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 16),
        )
      ],
    );
  }
}

class Prefs extends StatefulWidget {
  Prefs({
    Key key,
  }) : super(key: key);

  @override
  _PrefsState createState() => _PrefsState();
}

class _PrefsState extends State<Prefs> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          child: SizedBox(
            child: Row(
              children: [
                Checkbox(
                  value: isDetermine,
                  onChanged: (checked) {
                    setState(() {
                      isDetermine = checked;
                    });
                  },
                ),
                Text("改为行列式而不是矩阵"),
              ],
            ),
          ),
        ),
        Container(
          child: SizedBox(
            child: Row(
              children: [
                Checkbox(
                  value: asBlock,
                  onChanged: (checked) {
                    setState(() {
                      asBlock = checked;
                    });
                  },
                ),
                Text("加\$\$作为整块公式，而不是行内"),
              ],
            ),
          ),
        )
      ],
    );
  }
}
