import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xaekxettvmscwnowutrq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhhZWt4ZXR0dm1zY3dub3d1dHJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDE5NzAsImV4cCI6MjA4OTY3Nzk3MH0.YfhDxKcsOyw_UUf_iGCxH0sej4Hs0KhNz2RPHMCHKLU',
  );

  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugRepaintRainbowEnabled = false;
  debugPaintPointersEnabled = false;

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Color(0x00000000)),
  );

  runApp(const NewShangliApp());
}
