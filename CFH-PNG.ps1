Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$source = @"
using System;
using System.Drawing;
using System.IO;
using System.Diagnostics;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
public sealed class CfhPngForm : Form {
  readonly TextBox input=new TextBox(), output=new TextBox();
  readonly Label status=new Label();
  readonly Button run=new Button();
  readonly string engine;
  public CfhPngForm(string path) {
    engine=path; Text="CFH PNG"; Name="CfhPng"; StartPosition=FormStartPosition.CenterScreen; ClientSize=new Size(720,270); MinimumSize=new Size(650,300); Font=new Font("Segoe UI",10);
    var title=new Label { Text="Make a smaller PNG copy", Font=new Font("Segoe UI",16,FontStyle.Bold), AutoSize=true, Location=new Point(20,15) };
    var help=new Label { Text="Choose a PNG and where to save its optimized copy.", AutoSize=true, Location=new Point(22,52) };
    var inLabel=new Label { Text="Original PNG", AutoSize=true, Location=new Point(22,86) };
    input.SetBounds(25,110,525,28); input.Anchor=AnchorStyles.Top|AnchorStyles.Left|AnchorStyles.Right; input.AccessibleName="Original PNG";
    var choose=new Button { Text="Choose...", Location=new Point(565,106), Size=new Size(125,34), Anchor=AnchorStyles.Top|AnchorStyles.Right };
    choose.Click+=(s,e)=>{ using(var d=new OpenFileDialog { Filter="PNG images|*.png", CheckFileExists=true, Title="Choose a PNG image" }) { if(d.ShowDialog(this)==DialogResult.OK) { input.Text=d.FileName; output.Text=Path.Combine(Path.GetDirectoryName(d.FileName),Path.GetFileNameWithoutExtension(d.FileName)+"-optimized.png"); } } };
    var outLabel=new Label { Text="Save copy as", AutoSize=true, Location=new Point(22,150) };
    output.SetBounds(25,174,525,28); output.Anchor=AnchorStyles.Top|AnchorStyles.Left|AnchorStyles.Right; output.AccessibleName="Save copy as";
    var browse=new Button { Text="Browse...", Location=new Point(565,170), Size=new Size(125,34), Anchor=AnchorStyles.Top|AnchorStyles.Right };
    browse.Click+=(s,e)=>{ using(var d=new SaveFileDialog { Filter="PNG images|*.png", DefaultExt="png", AddExtension=true, OverwritePrompt=true, FileName=output.Text, Title="Save optimized copy" }) { if(d.ShowDialog(this)==DialogResult.OK) output.Text=d.FileName; } };
    run.Text="Optimize"; run.SetBounds(565,215,125,34); run.Anchor=AnchorStyles.Top|AnchorStyles.Right; run.Click+=Optimize;
    status.Text="The original file is kept."; status.SetBounds(25,219,525,35); status.Anchor=AnchorStyles.Top|AnchorStyles.Left|AnchorStyles.Right;
    Controls.AddRange(new Control[]{title,help,inLabel,input,choose,outLabel,output,browse,run,status}); AcceptButton=run;
  }
  static string Quote(string s) { var b=new StringBuilder("\""); int n=0; foreach(char c in s) { if(c=='\\'){ n++; continue; } if(c=='\"'){ b.Append('\\',n*2+1); b.Append('\"'); n=0; continue; } b.Append('\\',n); n=0; b.Append(c); } b.Append('\\',n*2); b.Append('\"'); return b.ToString(); }
  async void Optimize(object sender,EventArgs e) {
    string src, dst;
    try { src=Path.GetFullPath(input.Text); dst=Path.GetFullPath(output.Text); }
    catch { status.Text="Choose valid input and output paths."; return; }
    if(!File.Exists(src)) { status.Text="Choose an existing PNG file."; return; }
    if(!String.Equals(Path.GetExtension(src),".png",StringComparison.OrdinalIgnoreCase) || !String.Equals(Path.GetExtension(dst),".png",StringComparison.OrdinalIgnoreCase)) { status.Text="Choose PNG files for the original and copy."; return; }
    if(String.Equals(src,dst,StringComparison.OrdinalIgnoreCase)) { status.Text="Choose a different name for the copy."; return; }
    if(File.Exists(dst)) { status.Text="That copy already exists. Choose another name."; return; }
    if(!File.Exists(engine)) { status.Text="Optimizer missing. Reinstall CFH PNG."; return; }
    string temp=Path.Combine(Path.GetDirectoryName(dst),".cfh-"+Guid.NewGuid().ToString("N")+".png");
    run.Enabled=false; status.Text="Optimizing...";
    try {
      var p=new Process { StartInfo=new ProcessStartInfo { FileName=engine, Arguments="--force --max-raw-size 256MB --out "+Quote(temp)+" -- "+Quote(src), UseShellExecute=false, CreateNoWindow=true, RedirectStandardError=true, RedirectStandardOutput=true } };
      p.Start();
      var error=p.StandardError.ReadToEndAsync(); var stdout=p.StandardOutput.ReadToEndAsync();
      await Task.Run(()=>p.WaitForExit()); await Task.WhenAll(error,stdout);
      if(p.ExitCode!=0 || !File.Exists(temp)) { status.Text="Could not optimize this image. Check the file and try again."; }
      else { File.Move(temp,dst); long before=new FileInfo(src).Length, after=new FileInfo(dst).Length; status.Text="Saved copy: "+after.ToString("N0")+" bytes (original "+before.ToString("N0")+")."; }
    } catch(Exception) { status.Text="Could not save the copy. Check the folder and try again."; }
    finally { try { if(File.Exists(temp)) File.Delete(temp); } catch {} run.Enabled=true; }
  }
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies System.Windows.Forms,System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run((New-Object CfhPngForm (Join-Path $PSScriptRoot 'oxipng.exe')))