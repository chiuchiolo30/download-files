import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Download file',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Download File'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Dio _dio = Dio();
  final TextEditingController _controller = TextEditingController();

  late String porcentagem = '0';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(
                height: 20,
              ),
              Row(
                children: const [
                  Text('Download file from url'),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: _controller,
                onSubmitted: (_) => porcentagem == '0' ? downloadFile() : null,
                enabled: porcentagem == '0',                
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter URL',
                ),
              ),
              if (porcentagem != '0')
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(2),
                  height: 16.0,
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width *
                      double.parse(porcentagem),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 1, 26, 213),
                        Color.fromARGB(255, 20, 243, 9)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Text(
                    '$porcentagem%',
                    style: const TextStyle(color: Colors.white, fontSize: 10.0),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () => porcentagem == '0' ? downloadFile() : clear(),                
                icon:  porcentagem == '0' ? const Icon(Icons.download) : const Icon(Icons.clear),
                label: porcentagem == '0' ? const Text('Download') : const Text('Clear'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void downloadFile() async {

    final String url = _controller.text;

    if (url.isEmpty) return;
    if (!Uri.parse(url).isAbsolute) return;
    if (!url.contains('https://'))  return;

    const extensionesPermitidas = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'mp3', 'mp4', 'avi', 'mov', 'jpg', 'png', 'gif', 'jpeg'];
    final extensionUrl = url.split('.').last;

    if (!extensionesPermitidas.contains(extensionUrl)) return;

    final permission = await Permission.storage.status;
    
    if (permission.isGranted || await Permission.storage.request().isGranted) {
      final response = await _dio.get(url,
          options: Options(
              responseType: ResponseType.bytes,
              followRedirects: false,
              receiveTimeout: 0), onReceiveProgress: (int received, int total) {
        if (total != -1) {
          log('Received: $received, Total: $total');
          log((received / total * 100).toStringAsFixed(2));
          porcentagem = (received / total * 100).toStringAsFixed(2);
          setState(() {});
          if (received == total) {
            showTopSnackBar(
                context,
                const CustomSnackBar.success(
                  message: 'Download completed',
                ));
          }
        }
      });

      if (response.statusCode == 200) {
        final fileName = url.substring(url.lastIndexOf('/') + 1);
        final ext = fileName.substring(fileName.lastIndexOf('.') + 1);
        final appDocPath = "/storage/emulated/0/Download/$ext/";

        final filePath = appDocPath + fileName;
        final dir = Directory(appDocPath);

        if (!dir.existsSync()) dir.createSync(recursive: true);

        final File file = File(filePath);
        if (file.existsSync()) {
          showTopSnackBar(
              context,
              const CustomSnackBar.info(
                message: 'File already exists',
              ));
        }
        final _raf = file.openSync(mode: FileMode.write);
        _raf.writeFromSync(response.data);
        await _raf.close();
      } else {
        showTopSnackBar(
            context,
            CustomSnackBar.error(
              message:
                  'File download failed - network error - status code: ${response.statusCode}',
            ));
      }
    } else {
      showTopSnackBar(
          context,
          const CustomSnackBar.info(
            message: 'Permission denied, please grant storage permission.',
          ));
    }
  }

  void clear() {
    _controller.clear();
    porcentagem = '0';
    setState(() {});
    FocusScope.of(context).unfocus();
  }
}
