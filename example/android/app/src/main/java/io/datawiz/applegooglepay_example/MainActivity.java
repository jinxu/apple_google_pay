package io.datawiz.applegooglepay_example;

//

import android.os.Bundle;

import androidx.annotation.NonNull;

import io.datawiz.applegooglepay.ApplegooglepayPlugin;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry;
//
//public class MainActivity extends FlutterActivity {
//    @Override
//    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
////        GeneratedPluginRegistrant.registerWith(flutterEngine);
//        GeneratedPluginRegistrant.registerWith(this);
//
//    }
//}
//
//

public class MainActivity extends io.flutter.app.FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);


    }
}
