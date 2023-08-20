using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;
using System.IO;

public partial class XFileClass : System.IDisposable
{
        private string filePath;
        public XFileClass(string fPath) //通过文件路径初始化对象
        {
            filePath = fPath;
            if( !System.IO.File.Exists( filePath ) ) {
                Debug.LogError( filePath +"该文件不存在,请检查路径!" );
                return;
            }
        }
      // 替换某些字符串
        public void ReplaceString(string oldStr,string newStr,string method="")  
        {  
            if (!File.Exists (filePath))   
            {  
                return;  
            }  
            bool getMethod = false;  
            string[] codes = File.ReadAllLines (filePath);  
            for (int i=0; i<codes.Length; i++)   
            {  
                string str=codes[i].ToString();  
                if(string.IsNullOrEmpty(method))  
                {  
                    if(str.Contains(oldStr))codes.SetValue(newStr,i);  
                }  
                else  
                {  
                    if(!getMethod)  
                    {  
                        getMethod=str.Contains(method);  
                    }  
                    if(!getMethod)continue;  
                    if(str.Contains(oldStr))  
                    {  
                        codes.SetValue(newStr,i);  
                        break;  
                    }  
                }  
            }  
            File.WriteAllLines (filePath, codes);  
        }  
      // 在某一行后面插入代码
        public void WriteBelowCode(string below, string text)
        {
            StreamReader streamReader = new StreamReader(filePath);
            string text_all = streamReader.ReadToEnd();
            streamReader.Close();

            int beginIndex = text_all.IndexOf(below);
            if(beginIndex == -1){
                return; 
            }
            int endIndex = text_all.LastIndexOf("\n", beginIndex + below.Length);

            text_all = text_all.Substring(0, endIndex) + "\n"+text+"\n" + text_all.Substring(endIndex);

            StreamWriter streamWriter = new StreamWriter(filePath);
            streamWriter.Write(text_all);
            streamWriter.Close();
        }
        public void WriteBeforeCode(string before, string text)
        {
            StreamReader streamReader = new StreamReader(filePath);
            string text_all = streamReader.ReadToEnd();
            streamReader.Close();

            int beginIndex = text_all.IndexOf(before);
            if(beginIndex == -1){
                return; 
            }

            text_all = text_all.Substring(0, beginIndex) + "\n"+text+"\n" + text_all.Substring(beginIndex);

            StreamWriter streamWriter = new StreamWriter(filePath);
            streamWriter.Write(text_all);
            streamWriter.Close();
        }
        public void Dispose()
        {

        }
}

public static class BuildiOS
{
    private static void AddLibToProject(PBXProject proj, string target, string lib) 
    {
        string file = proj.AddFile("usr/lib/" + lib, "Frameworks/" + lib, PBXSourceTree.Sdk);
        proj.AddFileToBuild(target, file);
    }

    private static string GetWebSDKCallCode(string VersionKey)
    {
        string Code = @"SotApplyCachedResult applyShipResult = [SotWebService ApplyCachedAndPullShip:@""" + VersionKey + @""" is_dev:false cb:^(SotDownloadScriptStatus status)
        {
            if(status == SotScriptShipAlreadyNewest)
            {
                NSLog(@""SyncOnly SotScriptShipAlreadyNewest"");
            }
            else if(status == SotScriptShipHasSyncNewer)
            {
                NSLog(@""SyncOnly SotScriptShipHasSyncNewer"");
            }
            else if(status == SotScriptShipDisable)
            {
                NSLog(@""SyncOnly SotScriptShipDisable"");
            }
            else
            {
                NSLog(@""SyncOnly SotScriptStatusFailure"");
            }
        }];
        if(applyShipResult.Success)
        {
            if(applyShipResult.ShipMD5)
                NSLog(@""sot success apply cached ship md5:%@"", applyShipResult.ShipMD5);
        }";
        return Code;
    }

    [PostProcessBuild]
    public static void OnPostprocessBuild(BuildTarget buildTarget, string path)
    {
        if (buildTarget != BuildTarget.iOS)
        {
            return;
        }
        string projPath = path + "/Unity-iPhone.xcodeproj/project.pbxproj";
        PBXProject proj = new PBXProject();
        proj.ReadFromFile(projPath);


        //对Target进行热更注入和编译补丁
        string main_target = proj.TargetGuidByName(PBXProject.GetUnityTargetName());
        // 为false则配置为接入接入免费版，适合本地测试，true则接入网站版适合正式上线使用
        bool bIsWebsiteVersion = true;
        //添加SOT专属的编译配置
        //-sotmodule UnityFramework代表该module的名字
        // 这里假设已经把SOT SDK解压到了/Users/sotsdk-1.0目录中，解压到别的目录也可以，改成别的路径，下面的步骤也需要修改成正确的路径
        // /Users/sotsdk-1.0/libs/libsot_free.a是免费版的SOT的库文件，可以用于本地测试使用。
        // /Users/sotsdk-1.0/libs/libsot_web.a是网站版的SOT的库文件，用于正式上线使用。
        // -sotsaved $(SRCROOT)/sotsaved/$(CONFIGURATION)/$(CURRENT_ARCH) 是表示把编译结果保存在该目录中，$(SRCROOT)就是xcode项目根目录的变量
        // -sotconfig $(SRCROOT)/sotconfig.sh 表示sotconfig.sh的保存地址，用来控制是热更注入编译，还是补丁编译
        if(bIsWebsiteVersion)
            proj.AddBuildProperty (main_target, "OTHER_LDFLAGS", "-sotmodule UnityFramework /Users/sotsdk-1.0/libs/libsot_web.a -sotsaved $(SRCROOT)/sotsaved/$(CONFIGURATION)/$(CURRENT_ARCH) -sotconfig $(SRCROOT)/sotconfig.sh");
        else
            proj.AddBuildProperty (main_target, "OTHER_LDFLAGS", "-sotmodule UnityFramework /Users/sotsdk-1.0/libs/libsot_free.a -sotsaved $(SRCROOT)/sotsaved/$(CONFIGURATION)/$(CURRENT_ARCH) -sotconfig $(SRCROOT)/sotconfig.sh");

        // 对il2cpp生成的C++文件进行热更注入
        proj.AddBuildProperty (main_target, "OTHER_CFLAGS", "-sotmodule UnityFramework -sotconfig $(SRCROOT)/sotconfig.sh");
        //禁用BITCODE
        proj.SetBuildProperty(main_target, "ENABLE_BITCODE", "false");
        //增加c++库和libz压缩库，用来解压补丁
        AddLibToProject(proj, main_target,"libc++.tbd");
        AddLibToProject(proj, main_target,"libz.tbd");

        
        //增加补丁拷贝脚本，补丁生成在上面配置的 sotsaved目录/ship/ship.sot文件中，会被这个脚本拷贝到bundle目录下，这样免费版就能本地测试了。
        string shellScriptPath="sh /Users/sotsdk-1.0/project-script/sot_package.sh \"$SOURCE_ROOT/sotconfig.sh\" \"$SOURCE_ROOT/sotsaved/$CONFIGURATION\" UnityFramework";
        proj.AddShellScriptBuildPhase(main_target,"copy sot ship", "/bin/sh", shellScriptPath);
        File.WriteAllText(projPath, proj.WriteToString());

        //增加SOT SDK接口的调用，用来加载补丁 
        XFileClass Preprocessor = new XFileClass(path + "/Classes/main.mm");
        //添加SDK头文件
        Preprocessor.WriteBelowCode("#include <csignal>","#import \"/Users/sotsdk-1.0/libs/SotWebService.h\"");
        //添加调用代码来加载补丁
        if(bIsWebsiteVersion)
        {
            //去SOT官网注册(https://www.sotvm.com) 后，创建APP->创建版本，就能得到唯一的版本VersionKey，把下面12345678替换成正式的VersionKey即可
            string VersionKey = @"12345678";
            Preprocessor.WriteBeforeCode("UnityInitStartupTime();", GetWebSDKCallCode(VersionKey));
        }
        else
        {
            //免费版能从Bundle中加载补丁文件，可以用于本地测试SOT功能把
            Preprocessor.WriteBeforeCode("UnityInitStartupTime();", "[SotWebService ApplyBundleShip];");
        }
         
        //添加签名
        // proj.SetBuildProperty(main_target, "CODE_SIGN_STYLE", "Automatic");
        // proj.SetTeamId(main_target, "4MDRX4VDLN");
        File.WriteAllText(projPath, proj.WriteToString());

    }
}