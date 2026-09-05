import os
import subprocess
import shutil
import markdown

md_file_path = r"C:\Users\sorna\.gemini\antigravity\brain\95b67dc7-657f-4ab2-90ab-2b45fba246d7\patent_specification.md"
html_out_path = r"c:\Users\sorna\.gemini\antigravity\scratch\vision_assistant\patent_specification_full.html"
pdf_workspace_path = r"c:\Users\sorna\.gemini\antigravity\scratch\vision_assistant\Vision_Assistant_Patent_Specification.pdf"
pdf_artifact_path = r"C:\Users\sorna\.gemini\antigravity\brain\95b67dc7-657f-4ab2-90ab-2b45fba246d7\Vision_Assistant_Patent_Specification.pdf"

# Read markdown content
with open(md_file_path, 'r', encoding='utf-8') as f:
    md_text = f.read()

# Convert markdown to html
html_body = markdown.markdown(md_text, extensions=['fenced_code', 'tables', 'attr_list'])

# Wrap in CSS template
full_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Patent Specification - Vision Assistant</title>
<style>
  @page {{
    size: letter;
    margin: 20mm 18mm 20mm 18mm;
  }}

  body {{
    font-family: 'Times New Roman', Times, Georgia, serif;
    font-size: 11pt;
    line-height: 1.6;
    color: #000000;
    margin: 0;
    padding: 0;
  }}

  h1 {{
    font-size: 16pt;
    text-align: center;
    text-transform: uppercase;
    margin-bottom: 5px;
    border-bottom: 2px solid #000;
    padding-bottom: 8px;
  }}

  h2 {{
    font-size: 13pt;
    text-transform: uppercase;
    border-bottom: 1px solid #333;
    padding-bottom: 4px;
    margin-top: 24px;
    margin-bottom: 12px;
    page-break-after: avoid;
  }}

  h3 {{
    font-size: 11.5pt;
    font-weight: bold;
    margin-top: 18px;
    margin-bottom: 8px;
    page-break-after: avoid;
  }}

  h4 {{
    font-size: 11pt;
    font-weight: bold;
    margin-top: 14px;
    margin-bottom: 6px;
    page-break-after: avoid;
  }}

  p {{
    text-align: justify;
    margin-bottom: 10px;
  }}

  ul, ol {{
    margin-top: 4px;
    margin-bottom: 12px;
    padding-left: 24px;
  }}

  li {{
    margin-bottom: 6px;
    text-align: justify;
  }}

  pre {{
    background-color: #f8f9fa;
    border: 1px solid #dcdcdc;
    border-radius: 4px;
    padding: 10px 14px;
    font-family: 'Consolas', 'Courier New', Courier, monospace;
    font-size: 8.5pt;
    line-height: 1.25;
    white-space: pre;
    overflow-x: auto;
    margin: 12px 0;
    page-break-inside: avoid;
  }}

  code {{
    font-family: 'Consolas', 'Courier New', Courier, monospace;
    background-color: #f1f1f1;
    padding: 1px 4px;
    font-size: 9.5pt;
    border-radius: 3px;
  }}

  pre code {{
    background-color: transparent;
    padding: 0;
    font-size: 8.5pt;
  }}

  blockquote {{
    border-left: 3px solid #000;
    margin: 12px 0;
    padding-left: 12px;
    font-style: italic;
  }}

  hr {{
    border: none;
    border-top: 1px solid #ccc;
    margin: 20px 0;
  }}

  strong {{
    color: #000;
  }}
</style>
</head>
<body>
{html_body}
</body>
</html>
"""

# Write HTML file
with open(html_out_path, 'w', encoding='utf-8') as f:
    f.write(full_html)

print("HTML written to:", html_out_path)

# Convert HTML to PDF using MS Edge
edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
cmd = [
    edge_path,
    "--headless=new",
    f"--print-to-pdf={pdf_workspace_path}",
    "--no-pdf-header-footer",
    f"file:///{html_out_path.replace('\\', '/')}"
]

print("Executing Edge PDF conversion...")
res = subprocess.run(cmd, capture_output=True, text=True)
print("Returncode:", res.returncode)

if os.path.exists(pdf_workspace_path):
    size = os.path.getsize(pdf_workspace_path)
    print(f"PDF generated successfully! Size: {size} bytes")
    shutil.copyfile(pdf_workspace_path, pdf_artifact_path)
    print("PDF copied to artifact path successfully.")
else:
    print("PDF generation failed.")
