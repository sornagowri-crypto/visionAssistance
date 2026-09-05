import subprocess
import os
import shutil

html_path = r"c:\Users\sorna\.gemini\antigravity\scratch\vision_assistant\patent_specification.html"
pdf_workspace_path = r"c:\Users\sorna\.gemini\antigravity\scratch\vision_assistant\Vision_Assistant_Patent_Specification.pdf"
pdf_artifact_path = r"C:\Users\sorna\.gemini\antigravity\brain\95b67dc7-657f-4ab2-90ab-2b45fba246d7\Vision_Assistant_Patent_Specification.pdf"

edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# Run msedge headless
cmd = [
    edge_path,
    "--headless=new",
    f"--print-to-pdf={pdf_workspace_path}",
    "--no-pdf-header-footer",
    f"file:///{html_path.replace('\\', '/')}"
]

print("Running command:", " ".join(cmd))
res = subprocess.run(cmd, capture_output=True, text=True)
print("Returncode:", res.returncode)

if os.path.exists(pdf_workspace_path):
    print("PDF generated successfully:", os.path.getsize(pdf_workspace_path), "bytes")
    shutil.copyfile(pdf_workspace_path, pdf_artifact_path)
    print("Copied to artifact path successfully.")
else:
    print("PDF file not found after Edge command.")
