cd ..
folder = what('.');
classes = folder.classes;
!rm -rf setup/jekyll
!mkdir setup/jekyll
for i = 1: length(classes)
    html = help2html(classes{i});
    preface = sprintf(['---\r\n' ...
        'title: %s\r\n'...
        'keywords: documentation theme, jekyll, technical writers, help authoring tools, hat replacements\r\n'...
        'last_updated: July 3, 2016\r\n'...
        'tags: [getting_started]\r\n'...
        'sidebar: matlab_docs_sidebar\r\n'...
        'permalink: %s.html\r\n'...
        'folder: mydoc\r\n'...
        '---\r\n'], classes{i},classes{i});
    
    [a,b]=regexp(html,'<head>.*?</head>');
    html(a(1):b(1)) = [];
    [a,b]=regexp(html,'<div class="title">.*?</div>');
    html(a(1):b(1)) = [];
    [a,b]=regexp(html,'<table.*?</table>');
    html(a(1):b(1)) = [];
    h = fopen(sprintf('docs/pages/matlabClasses/%s.html',classes{i}),'wt');
    fprintf(h, preface);
    fprintf(h,'%s',html);
    fclose(h);
end

