cd ..
folder = what('.');
classes = folder.classes;
!rm -rf docs/pages/matlabClasses/*

% Remove classes that we don't need to document
classes(strcmp('IniConfig',classes)) = [];

% Remove some methods
blockmethods = {'addlistener' 'delete' 'disp' 'eq' 'ge' 'ne' 'gt'  ...
            'le' 'lt' 'notify' 'isvalid' 'findobj' 'findprop' 'copy' ...
            'addprop' 'listener' 'cat' 'horzcat' 'vertcat' 'displayEmptyObject' ...
            'displayScalarHandleToDeletedObject' 'displayScalarObject' ...
            'getDefaultScalarElement' 'displayNonScalarObject' , ...
            'getPropertyGroups' 'getFooter' 'getHeader' 'createFromResponse'};

toc = struct('section',[],'name',[],'loc',[]);
tocIdx = 1;
for i = 1: length(classes)
    fprintf('%i\n',i);
    curClass = classes{i};
    html = help2html(curClass);
    
    classLoc = sprintf('%s.html',lower(classes{i}));
    className = classes{i};
    preface = sprintf(['---\r\n' ...
        'title: %s\r\n'...
        'keywords: documentation theme, jekyll, technical writers, help authoring tools, hat replacements\r\n'...
        'last_updated: %s\r\n'...
        'sidebar: matlab_docs_sidebar\r\n'...
        'permalink: %s\r\n'...
        'folder: mydoc\r\n'...
        '---\r\n'], className, datestr(now,'mmm dd, yyyy'), classLoc);
    
    toc(tocIdx).section = 'class';
    toc(tocIdx).name = className;
    toc(tocIdx).loc = classLoc;
    tocIdx = tocIdx + 1;
    
    [a,b]=regexp(html,'<head>.*?</head>');
    html(a(1):b(1)) = [];
    [a,b]=regexp(html,'<div class="title">.*?</div>');
    html(a(1):b(1)) = [];
    [a,b]=regexp(html,'<table.*?</table>');
    html(a(1):b(1)) = [];
    
    htmlb = html(end:-1:1);
    lenhtml = length(html);
    for j=1: length(blockmethods)
        [a1, b1]=regexp(html,sprintf(">%s<.*?</tr>", blockmethods{j}));
        if ~isempty(a1)
            htmlb = html(1:a1(1));
            [a2, b2]=regexp(htmlb(end:-1:1),"(rt<)?");
            html(a1(1)-a2(1)-1:b1(1)) = [];
        end
    end
    
    
    
    % replace Class links
    [links,startLink,endLink] = regexp(html,...
        '<a href="matlab:helpwin\(\''(?<class>[\w]+)\'')\">[\w]+</a>','names');
    
    for iLink=1: length(links)
        if any(strcmp(links(iLink).class, classes))
            
            linkLoc = sprintf('%s.html',lower(links(iLink).class));
            str = sprintf('<a href="%s">%s</a>',linkLoc, links(iLink).class);
            lengthdiff = length(str) - (endLink(iLink)-startLink(iLink)) -1;

        else
            str = links(iLink).class;
            lengthdiff = length(str) - (endLink(iLink)-startLink(iLink)) -1;
        end
        html(startLink(iLink):endLink(iLink)) = [];
        html = insertBefore(html, startLink(iLink), str); 
        startLink = startLink + lengthdiff;
        endLink = endLink + lengthdiff;
        
    end

    % Replace properties and methods links
    [curMethods, methodsFull] = methods(curClass);
    [links,startLink,endLink] = regexp(html,...
        '<a href="matlab:helpwin\(\''(?<class>[\w]+)\.(?<method>[\w]+)\'')\">[\w]+</a>','names');
    
    % Find method origin
    methodOrigins = {methodsFull{:,4}};
    splitMethods = cellfun(@(x) strsplit(x,'.'), methodOrigins,'UniformOutput',false);
    
    
    
    
    for iLink=1: length(links)
        classOrigin = '';
        for iM=1:length(splitMethods)
            if strcmp(splitMethods{iM}{2}, links(iLink).method)
                classOrigin = splitMethods{iM}{1};
            end
        end
        
        if isempty(classOrigin)
            str = sprintf('%s',links(iLink).method);
        else
            linkLoc = sprintf('%s_%s.html',lower(classOrigin), lower(links(iLink).method));
            str = sprintf('<a href="%s">%s</a>',linkLoc, links(iLink).method);
        end

        lengthdiff = length(str) - (endLink(iLink)-startLink(iLink)) -1;
        
        html(startLink(iLink):endLink(iLink)) = [];
        html = insertBefore(html, startLink(iLink), str); 
        startLink = startLink + lengthdiff;
        endLink = endLink + lengthdiff;
        
    end
    
    % replace remaining links
    [links,startLink,endLink] = regexp(html,...
        '<a href="matlab:helpwin\(\''(?<class>[\w\.]+)\'')\">[\w\.]+</a>','names');
    
    for iLink=1: length(links)
        str = links(iLink).class;
        lengthdiff = length(str) - (endLink(iLink)-startLink(iLink)) -1;
        html(startLink(iLink):endLink(iLink)) = [];
        html = insertBefore(html, startLink(iLink), str); 
        startLink = startLink + lengthdiff;
        endLink = endLink + lengthdiff;
        
    end
    
    
    h = fopen(sprintf('docs/pages/matlabClasses/%s',classLoc),'wt');
    fprintf(h, preface);
    fprintf(h,'%s',html);
    fclose(h);
            
    
    % Iterate over methods
    if strcmp('curClass','Blackfynn')
        curClass = 'Blackfynn(''empty'')';
    end
    
    try
        for j=1: length(curMethods)
            if any(strcmp(curMethods{j},blockmethods))
                continue;
            end
            
            % Check that method does not belong to parent-class
            if ~any(strcmp(sprintf('%s.%s',curClass,curMethods{j}),{methodsFull{:,4}}))
                continue
            end
    
            fprintf('%s',j);
            html = help2html(sprintf('%s.%s',curClass,curMethods{j}));
            
            methodName = sprintf('(%s) %s',classes{i},curMethods{j});
            methodLoc = sprintf('%s_%s.html',lower(classes{i}),lower(curMethods{j}));
            preface = sprintf(['---\r\n' ...
            'title: %s\r\n'...
            'keywords: documentation theme, jekyll, technical writers, help authoring tools, hat replacements\r\n'...
            'last_updated: July 3, 2016\r\n'...
            'tags: [getting_started]\r\n'...
            'sidebar: matlab_docs_sidebar\r\n'...
            'permalink: %s\r\n'...
            'folder: mydoc\r\n'...
            '---\r\n'], methodName, methodLoc);

            [a,b]=regexp(html,'<head>.*?</head>');
            html(a(1):b(1)) = [];
            [a,b]=regexp(html,'<div class="title">.*?</div>');
            html(a(1):b(1)) = [];
            [a,b]=regexp(html,'<table.*?</table>');
            html(a(1):b(1)) = [];

            htmlb = html(end:-1:1);
            lenhtml = length(html);
            for k=1: length(blockmethods)
                [a1, b1]=regexp(html,sprintf(">%s<.*?</tr>",blockmethods{k}));
                if ~isempty(a1)
                    htmlb = html(1:a1(1));
                    [a2, b2]=regexp(htmlb(end:-1:1),"(rt<)?");
                    html(a1(1)-a2(1)-1:b1(1)) = [];
                end
            end

            h = fopen(sprintf('docs/pages/matlabClasses/%s',methodLoc),'wt');
            fprintf(h, preface);
            fprintf(h,'%s',html);
            fclose(h);
            
            toc(tocIdx).section = 'method';
            toc(tocIdx).name = methodName;
            toc(tocIdx).loc = methodLoc;
            tocIdx = tocIdx + 1;
        end
        
        
        
    catch ME
        fprintf(2,'Skipping class: %s\n',curClass);
    end
    
    % Create TOC
    h = fopen('docs/_data/sidebars/matlab_docs_partial.yaml','rt');
    txt = char(fread(h,'uint8')');
    fclose(h);

    !rm docs/_data/sidebars/matlab_docs_sidebar.yaml
    h = fopen('docs/_data/sidebars/matlab_docs_sidebar.yaml','wt');
    fprintf(h,txt);
    fprintf(h, '\n  - title: Classes\n    output: web\n    folderitems:\n');
    for ii=1: length(toc)
        if strcmp(toc(ii).section,'class')
            fprintf(h, '    - title: %s\n      url: /%s\n      output: web\n', toc(ii).name,toc(ii).loc);
        end

    end
    fprintf(h, '  - title: Methods\n    output: web\n    folderitems:\n');
    for ii=1: length(toc)
        if strcmp(toc(ii).section,'method')
            fprintf(h, '    - title: %s\n      url: /%s\n      output: web\n', toc(ii).name,toc(ii).loc);
        end

    end
        
end

