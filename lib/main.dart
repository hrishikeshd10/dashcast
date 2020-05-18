import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

final url = "https://itsallwidgets.com/podcast/feed";

final storagePathSuffix = "dashcast/downloads";

Future<String> _getDownloadPath(String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final uriPathPrefix = dir.uri.path;
  final absolutePath = path.join(uriPathPrefix, fileName);
  print(" LOL LOL KLOLOLOLLOLO   $absolutePath");
  return absolutePath;
}

void main() => runApp(MyApp());

class PodCast with ChangeNotifier {
  RssFeed _rssFeed;
  RssItem _selectedItem;

  Map<String, bool> downloadStatus;

  RssFeed get feed => _rssFeed;

  void parse(String url) async {
    final res = await http.get(url);
    final xmlStr = res.body;

    _rssFeed = RssFeed.parse(xmlStr);
    notifyListeners();
  }

  RssItem get selectedItem => _selectedItem;

  set selectedItem(RssItem item) {
    _selectedItem = item;
    notifyListeners();
  }

  void download(RssItem item) async {
    final client = http.Client();

    final req = http.Request("GET", Uri.parse(item.guid));
    final res = await client.send(req);
    if (res.statusCode != 200) {
      throw Exception("Unexpeced HTTP Code: ${res.statusCode}");
    }

    /*
    print("Running Download");
    http.StreamedRequest req =
        http.StreamedRequest(
            'GET',
            Uri.parse(item.guid));
final futureRes = await req.send();
if(res.statusCode != 200)
  throw Exception('Unexpected HTTP code: ${res.statusCode}');

print('Starting stream');
res.stream.listen((bytes) {
  print('Recieve ${bytes.length} bytes');
});

*/

    File file = File(await _getDownloadPath(path.split(item.guid).last));
    res.stream.pipe(file.openWrite()).whenComplete(() {
      print("Download Complete!");
    });
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PodCast()..parse(url),
      child: MaterialApp(
        title: 'The Boring Show!',
        home: MhyPage(),
      ),
    );
  }
}

class MhyPage extends StatefulWidget {
  @override
  _MhyPageState createState() => _MhyPageState();
}

class _MhyPageState extends State<MhyPage> {
  var navIndex = 0;

  final pages = List<Widget>.unmodifiable([EpisodesPage(), DumyPage()]);

  final iconList =
      List<IconData>.unmodifiable([Icons.hot_tub, Icons.timelapse]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[navIndex],
      bottomNavigationBar: MyNavbar(
        iconList: iconList,
        onPressed: (i) {
          setState(() {
            navIndex = i;
          });
        },
        activeIndex: navIndex,
      ),
    );
  }
}

class MyNavbar extends StatefulWidget {
  final List<IconData> iconList;
  final Function(int) onPressed;
  final int activeIndex;

  const MyNavbar(
      {Key key,
      this.iconList,
      @required this.onPressed,
      @required this.activeIndex})
      : assert(iconList != null);

  @override
  _MyNavbarState createState() => _MyNavbarState();
}

class _MyNavbarState extends State<MyNavbar> with SingleTickerProviderStateMixin {
  double beaconRadius;
  double maxBeaconRadius = 20;
  double iconScale = 1;

  AnimationController animationController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    beaconRadius = 0.0;

    animationController =
        AnimationController(duration: Duration(milliseconds: 300), vsync: this);
  }

  @override
  void didUpdateWidget(MyNavbar oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    animationController.reset();

    final curve =
        CurvedAnimation(parent: animationController, curve: Curves.linear);
    Tween<double>(begin: 0, end: 1).animate(curve)
      ..addListener(() {
        setState(() {
          beaconRadius = maxBeaconRadius * curve.value;
          if (beaconRadius == maxBeaconRadius) beaconRadius = 0;

          if (curve.value < 0.5) {
            iconScale = 1 + curve.value * 2;
          } else {
            iconScale = 2 - curve.value;
          }
        });
      });
    animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 60,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (int i = 0; i < widget.iconList.length; i++)
            _NavbarItem(
              isActive: i == widget.activeIndex,
              iconData: widget.iconList[i],
              onPressed: ()=>widget.onPressed(i),
              beaconRadius: beaconRadius,
              maxBeaconRadius: maxBeaconRadius,
              iconScale: iconScale,
            )
        ]));
  }
}

class _NavbarItem extends StatelessWidget {
  final bool isActive;
  final double beaconRadius;
  final double maxBeaconRadius;
  final double iconScale;
  final IconData iconData;
  final VoidCallback onPressed;

  const _NavbarItem(
      {Key key,
      @required this.isActive,
      @required this.beaconRadius,
      @required this.maxBeaconRadius,
      @required this.iconScale,
      @required this.iconData,
      @required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BeaconPainter(
          beaconColor: Colors.purple,
          beaconRadius: isActive ? beaconRadius : 0,
          maxBeaconRadius: maxBeaconRadius),
      child: GestureDetector(
        child: Transform.scale(
          scale: isActive ? iconScale : 1,
          child: Icon(
            iconData,
            color: isActive ? Colors.yellow[700] : Colors.black54,
          ),
        ),
        onTap: () => onPressed,
      ),
    );
  }
}

class BeaconPainter extends CustomPainter {
  final double beaconRadius;
  final double maxBeaconRadius;
  final Color beaconColor;
  final Color endColor;

  BeaconPainter(
      {@required this.beaconRadius,
      @required this.maxBeaconRadius,
      @required this.beaconColor})
      : endColor = Color.lerp(beaconColor, Colors.white, 0.6);

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement Drawing procedure
    //For the first half make stroke width have it the same as radius and second half, make it smaller and smaller in the end

    var aniamtionProgress = beaconRadius / maxBeaconRadius;
    double strokeWidth = beaconRadius < maxBeaconRadius * 0.5
        ? beaconRadius
        : (maxBeaconRadius - beaconRadius);
    final paint = Paint()
      ..color = Color.lerp(beaconColor, endColor, aniamtionProgress)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(12, 12), beaconRadius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DumyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Text("Dummy Page"),
    );
  }
}

class EpisodesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Consumer<PodCast>(
      builder: (context, podcast, _) {
        return podcast.feed != null
            ? EpisodeList(
                rssFeed: podcast.feed,
              )
            : Center(child: CircularProgressIndicator());
      },
    ));
  }
}

class EpisodeList extends StatelessWidget {
  const EpisodeList({
    Key key,
    @required this.rssFeed,
  }) : super(key: key);

  final RssFeed rssFeed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: rssFeed.items
          .map((i) => ListTile(
                title: Text(i.title),
                subtitle: Text(
                  i.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_downward),
                  onPressed: () {
                    Provider.of<PodCast>(context, listen: false).download(i);
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text('Downloading ${i.title}'),
                    ));
                  },
                ),
                onTap: () {
                  Provider.of<PodCast>(context, listen: false).selectedItem = i;
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => PlayerPage()));
                },
              ))
          .toList(),
    );
  }
}

class PlayerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            Provider.of<PodCast>(context, listen: false).selectedItem.title),
      ),
      body: SafeArea(child: Player()),
    );
  }
}

class Player extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final item = Provider.of<PodCast>(context, listen: false).selectedItem;
    final podcast = Provider.of<PodCast>(context);
    return Column(
      children: <Widget>[
        Flexible(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Image.network(podcast.feed.image.url),
            )),
        Flexible(
          flex: 4,
          child: SingleChildScrollView(
              child: Text(podcast.selectedItem.description)),
        ),
        Flexible(flex: 2, child: AudioControls())
      ],
    );
  }
}

class AudioControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[PlayBackButton()],
    );
  }
}

class PlayBackButton extends StatefulWidget {
  @override
  _PlayBackButtonState createState() => _PlayBackButtonState();
}

class _PlayBackButtonState extends State<PlayBackButton> {
  bool _isPLaying = false;
  FlutterSoundPlayer _sound;

  Stream<PlayStatus> _playerSubscription;
  double playPosition;

  void stop() async {
    await _sound.stopPlayer();
    setState(() {
      _isPLaying = false;
    });
  }

  void play(String url) async {
    var url = "/data/user/0/com.example.dash_cast/app_flutter/episode-23.mp3";
    await _sound.startPlayer(url);
    _playerSubscription = _sound.onPlayerStateChanged
      ..listen((e) {
        if (e != null) {
          setState(() {
//            print(e.currentPosition);
            playPosition = (e.currentPosition / e.duration);
          });
        }
        setState(() {
          _isPLaying = true;
        });
      });
  }

  void fast_forward() {}

  void rewind() {}

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _sound = FlutterSoundPlayer();
    playPosition = 0;
  }

  @override
  Widget build(BuildContext context) {
    final item = Provider.of<PodCast>(context, listen: true).selectedItem;
    return Column(children: [
      Slider(
        value: playPosition,
        onChanged: null,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.fast_rewind,
            ),
            onPressed: null,
          ),
          IconButton(
              icon: _isPLaying ? Icon(Icons.stop) : Icon(Icons.play_arrow),
              onPressed: () {
                if (_isPLaying) {
                  stop();
                } else {
                  play(item.guid);
                }
              }),
          IconButton(
            icon: Icon(
              Icons.fast_forward,
            ),
            onPressed: null,
          ),
        ],
      ),
    ]);
  }
}
