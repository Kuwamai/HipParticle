using System;
using System.IO;
using UnityEditor;
using UnityEngine;

internal static class GameViewScreenshot
{
    [MenuItem("Tools/HipParticle/Save Game View PNG")]
    private static void Save()
    {
        if (!EditorApplication.isPlaying || EditorApplication.isPaused)
        {
            EditorUtility.DisplayDialog("Gameビューの保存", "Play中（一時停止していない状態）に実行してください。", "OK");
            return;
        }

        const string directory = @"C:\Users\mitum\Pictures\Screenshots";
        Directory.CreateDirectory(directory);
        string filename = "HipParticle-" + DateTime.Now.ToString("yyyyMMdd-HHmmss-fff") + ".png";
        string path = Path.Combine(directory, filename);

        // Gameビューを表示して次の更新で撮影する。
        if (!EditorApplication.ExecuteMenuItem("Window/General/Game"))
        {
            EditorUtility.DisplayDialog("Gameビューの保存", "Gameビューを開けませんでした。", "OK");
            return;
        }

        EditorApplication.delayCall += () =>
        {
            if (!EditorApplication.isPlaying || EditorApplication.isPaused)
                return;

            ScreenCapture.CaptureScreenshot(path, 1);
            Debug.Log("GameビューのPNG保存を開始しました: " + path);
        };
    }
}
