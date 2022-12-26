import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'artical_news.dart';
import 'constants.dart';
import 'list_of_country.dart';
import 'package:alan_voice/alan_voice.dart';

void main() => runApp(const MyApp());

GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

void toggleDrawer() {
  if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
    _scaffoldKey.currentState?.openEndDrawer();
  } else {
    _scaffoldKey.currentState?.openDrawer();
  }
}

class DropDownList extends StatelessWidget {
  const DropDownList({super.key, required this.name, required this.call});
  final String name;
  final Function call;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: ListTile(title: Text(name)),
      onTap: () => call(),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {
  _MyAppState() {
    /// Init Alan Button with project key from Alan Studio
    AlanVoice.addButton("a478b5a00b84881a1f2c7fcdd1110b212e956eca572e1d8b807a3e2338fdd0dc/stage",
    buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT);

    /// commands
  AlanVoice.callbacks.add((command) => _handleCommand(command.data));


    /// Handle commands from Alan Studio
    ///AlanVoice.onCommand.add((command) {
      ///debugPrint("got new command ${command.toString()}");
    ///});

  }
  dynamic cName;
  dynamic country;
  dynamic category;
  dynamic findNews;
  int pageNum = 1;
  bool isPageLoading = false;
  late ScrollController controller;
  int pageSize = 10;
  bool isSwitched = false;
  List<dynamic> news = [];
  bool notFound = false;
  List<int> data = [];
  bool isLoading = false;
  String baseApi = 'https://newsapi.org/v2/top-headlines?';



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'News',
      theme: isSwitched
          ? ThemeData(
              fontFamily: GoogleFonts.poppins().fontFamily,
              brightness: Brightness.light,
            )
          : ThemeData(
              fontFamily: GoogleFonts.poppins().fontFamily,
              brightness: Brightness.dark,
            ),



      home: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (country != null)
                    Text('Country = $cName')
                  else
                    Container(),
                  const SizedBox(height: 10),
                  if (category != null)
                    Text('Category = $category')
                  else
                    Container(),
                  const SizedBox(height: 20),
                ],
              ),
              ListTile(
                title: TextFormField(
                  decoration: const InputDecoration(hintText: 'Find Keyword'),
                  scrollPadding: const EdgeInsets.all(5),
                  onChanged: (String val) => setState(() => findNews = val),
                ),
                trailing: IconButton(
                  onPressed: () async => getNews(searchKey: findNews as String),
                  icon: const Icon(Icons.search),
                ),
              ),
              ExpansionTile(
                title: const Text('Country'),
                children: <Widget>[
                  for (int i = 0; i < listOfCountry.length; i++)
                    DropDownList(
                      call: () {
                        country = listOfCountry[i]['code'];
                        cName = listOfCountry[i]['name']!.toUpperCase();
                        getNews();
                      },
                      name: listOfCountry[i]['name']!.toUpperCase(),
                    ),
                ],
              ),
              ExpansionTile(
                title: const Text('Category'),
                children: [
                  for (int i = 0; i < listOfCategory.length; i++)
                    DropDownList(
                      call: () {
                        category = listOfCategory[i]['code'];
                        getNews();
                      },
                      name: listOfCategory[i]['name']!.toUpperCase(),
                    )
                ],
              ),
              ExpansionTile(
                title: const Text('Channel'),
                children: [
                  for (int i = 0; i < listOfNewsChannel.length; i++)
                    DropDownList(
                      call: () =>
                          getNews(channel: listOfNewsChannel[i]['code']),
                      name: listOfNewsChannel[i]['name']!.toUpperCase(),
                    ),
                ],
              ),
              //ListTile(title: Text("Exit"), onTap: () => exit(0)),
            ],
          ),
        ),
        appBar: AppBar(
          centerTitle: true,
          title: const Text('News'),
          actions: [
            IconButton(
              onPressed: () {
                country = null;
                category = null;
                findNews = null;
                cName = null;
                getNews(reload: true);
              },
              icon: const Icon(Icons.refresh),
            ),
            Switch(
              value: isSwitched,
              onChanged: (bool value) => setState(() => isSwitched = value),
              activeTrackColor: Colors.white,
              activeColor: Colors.white,
            ),
          ],
        ),
        body: notFound
            ? const Center(
                child: Text('Not Found', style: TextStyle(fontSize: 30)),
              )
            : news.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.yellow,
                    ),
                  )
                : ListView.builder(
                    controller: controller,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      fullscreenDialog: true,
                                      builder: (BuildContext context) =>
                                          ArticalNews(
                                        newsUrl: news[index]['url'] as String,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          if (news[index]['urlToImage'] == null)
                                            Container()
                                          else
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: CachedNetworkImage(
                                                placeholder:
                                                    (BuildContext context,
                                                            String url) =>
                                                        Container(),
                                                errorWidget:
                                                    (BuildContext context,
                                                            String url,
                                                            error) =>
                                                        const SizedBox(),
                                                imageUrl: news[index]
                                                    ['urlToImage'] as String,
                                              ),
                                            ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Card(
                                              elevation: 0,
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.8),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 8,
                                                ),
                                                child: Text(
                                                  "${news[index]['source']['name']}",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      Text(
                                        "${news[index]['title']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (index == news.length - 1 && isLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                backgroundColor: Colors.yellow,
                              ),
                            )
                          else
                            const SizedBox(),
                        ],
                      );
                    },
                    itemCount: news.length,
                  ),
      ),
    );
  }

  _handleCommand(Map<String, dynamic > response){
    String data;
    switch(response["command"]){
      case "refresh":
        getNews(reload: true);
        break;
      case "search":
        getNews(searchKey: response["data"]);
        break;
      case "theme":
        toggleDrawer();
        break;
      case "category":
        switch(response["data"]){
          case "science":
            category = listOfCategory[0]['code'];
            cName = listOfCategory[0]['name']!.toUpperCase();
            getNews();
            break;
          case "business":
            category = listOfCategory[1]['code'];
            cName = listOfCategory[1]['name']!.toUpperCase();
            getNews();
            break;
          case "technology":
            category = listOfCategory[2]['code'];
            cName = listOfCategory[2]['name']!.toUpperCase();
            getNews();
            break;
          case "sports":
            category = listOfCategory[3]['code'];
            cName = listOfCategory[3]['name']!.toUpperCase();
            getNews();
            break;
          case "health":
            category = listOfCategory[4]['code'];
            cName = listOfCategory[4]['name']!.toUpperCase();
            getNews();            break;
          case "general":
            category = listOfCategory[5]['code'];
            cName = listOfCategory[5]['name']!.toUpperCase();
            getNews();
            break;
          case "entertainment":
            category = listOfCategory[6]['code'];
            cName = listOfCategory[6]['name']!.toUpperCase();
            getNews();
            break;
        }
        baseApi += category == null ? '' : 'category=$category&';
        break;
      case "country":
        switch(response["data"]){
          case "Egypt":
            country = listOfCountry[0]['code'];
            cName = listOfCountry[0]['name']!.toUpperCase();
            getNews();
            break;
          case "Hungary":
            country = listOfCountry[1]['code'];
            cName = listOfCountry[1]['name']!.toUpperCase();
            getNews();
            break;
          case "USA":
            country = listOfCountry[2]['code'];
            cName = listOfCountry[2]['name']!.toUpperCase();
            getNews();
            break;
          case "United Arab Emirates":
            country = listOfCountry[3]['code'];
            cName = listOfCountry[3]['name']!.toUpperCase();
            getNews();
            break;
          case "Austria":
            country = listOfCountry[4]['code'];
            cName = listOfCountry[4]['name']!.toUpperCase();
            getNews();
            break;
          case "Poland":
            country = listOfCountry[5]['code'];
            cName = listOfCountry[5]['name']!.toUpperCase();
            getNews();
            break;
          case "Turkey":
            country = listOfCountry[6]['code'];
            cName = listOfCountry[6]['name']!.toUpperCase();
            getNews();
            break;
          case "China":
            country = listOfCountry[7]['code'];
            cName = listOfCountry[7]['name']!.toUpperCase();
            getNews();
            break;
          case "Russia":
            country = listOfCountry[8]['code'];
            cName = listOfCountry[8]['name']!.toUpperCase();
            getNews();
            break;
          case "United Kingdom":
            country = listOfCountry[9]['code'];
            cName = listOfCountry[9]['name']!.toUpperCase();
            getNews();
            break;
        }
      break;
      case "source":
        switch(response["data"]){
          case "BBC News":
            getNews(channel: 'bbc-news');
            break;
          case "The Washington Post":
            getNews(channel: 'the-washington-post');
            break;
          case "Reuters":
            getNews(channel: 'reuters');
            break;
          case "CNN":
            getNews(channel: 'cnn');
            break;

        }
    }

  }
  Future<void> getDataFromApi(String url) async {
    final http.Response res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      if (jsonDecode(res.body)['totalResults'] == 0) {
        notFound = !isLoading;
        setState(() => isLoading = false);
      } else {
        if (isLoading) {
          final newData = jsonDecode(res.body)['articles'] as List<dynamic>;
          for (final e in newData) {
            news.add(e);
          }
        } else {
          news = jsonDecode(res.body)['articles'] as List<dynamic>;
        }
        setState(() {
          notFound = false;
          isLoading = false;
        });
      }
    } else {
      setState(() => notFound = true);
    }
  }

  Future<void> getNews({
    String? channel,
    dynamic searchKey,
    bool reload = false,
  }) async {
    setState(() => notFound = false);

    if (!reload && !isLoading) {
      toggleDrawer();
    } else {
      country = null;
      category = null;
    }
    if (isLoading) {
      pageNum++;
    } else {
      setState(() => news = []);
      pageNum = 1;
    }
    baseApi = 'https://newsapi.org/v2/top-headlines?pageSize=10&page=$pageNum&';

    baseApi += country == null ? 'country=us&' : 'country=$country&';
    baseApi += category == null ? '' : 'category=$category&';
    baseApi += 'apiKey=$apiKey';
    if (channel != null) {
      country = null;
      category = null;
      baseApi =
          'https://newsapi.org/v2/top-headlines?pageSize=10&page=$pageNum&sources=$channel&apiKey=16e345c3c1364eaca6f409edf2ff6048';
    }
    if (searchKey != null) {
      country = null;
      category = null;
      baseApi =
          'https://newsapi.org/v2/top-headlines?pageSize=10&page=$pageNum&q=$searchKey&apiKey=16e345c3c1364eaca6f409edf2ff6048';

    }
    //print(baseApi);
    getDataFromApi(baseApi);

  }

  @override
  void initState() {
    controller = ScrollController()..addListener(_scrollListener);
    getNews();
    super.initState();
  }

  void _scrollListener() {
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      setState(() => isLoading = true);
      getNews();
    }
  }
}
