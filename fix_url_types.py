import re

with open('/Users/COBSCCOMP242P-064/dev/SafeWalk/SafeWalk.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Look for GENERATE_INFOPLIST_FILE = YES; and append the URL types right after it
if 'INFOPLIST_KEY_CFBundleURLTypes' not in content:
    replacement = """GENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleURLTypes = (
\t\t\t\t\t{
\t\t\t\t\t\tCFBundleTypeRole = Editor;
\t\t\t\t\t\tCFBundleURLSchemes = (
\t\t\t\t\t\t\t"com.safewalk.app",
\t\t\t\t\t\t);
\t\t\t\t\t},
\t\t\t\t);"""
    
    new_content = content.replace("GENERATE_INFOPLIST_FILE = YES;", replacement)
    
    with open('/Users/COBSCCOMP242P-064/dev/SafeWalk/SafeWalk.xcodeproj/project.pbxproj', 'w') as f:
        f.write(new_content)
    print("Injected URL Types successfully.")
else:
    print("URL Types already exist.")
