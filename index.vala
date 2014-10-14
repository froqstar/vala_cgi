


enum request_type {
	HOME,
    POST,
    IMAGE,
    CSS,
    IMPRINT
}

//const string BLOG_TITLE = "{madzone}";
//const string BLOG_SUBTITLE = "stuff about Linux, studies and life";
const string BLOG_TITLE = "{title}";
const string BLOG_SUBTITLE = "{subtitle}";

const string BASE_URL = "/blog/index.cgi";
const string BASEPATH_POSTS = "posts";
const string BASEPATH_STATIC = "static";
const int REQUEST_OFFSET = 3;

//request data
string request;
string[] request_parts;
string identifier;
string identifier_second;
string filetype;
request_type type = request_type.HOME;


public static int main(){

    request = Environment.get_variable("REQUEST_URI");

    if (request != null) parse_request(request);
    
    switch (type) {
        case request_type.POST:
            stdout.printf("Content-Type: text/html;charset=us-ascii\n\n");
            stdout.printf(create_post_page(identifier));
            break;
        case request_type.IMAGE:
            stdout.printf("Content-Type: image/%s\n\n", filetype);
            uint8[] data = readFileBinary(BASEPATH_POSTS + "/" + identifier + "/" + identifier_second);
            stdout.write(data, data.length);
            break;
        case request_type.CSS:
            stdout.printf("Content-Type: text/css;charset=us-ascii\n\n");
            stdout.printf(readFile(BASEPATH_STATIC + "/" + identifier));
            break;
        case request_type.HOME:
            stdout.printf("Content-Type: text/html;charset=us-ascii\n\n");
            stdout.printf(create_overview_page(5, int.parse(identifier?? "0"), 100));
            break;
        case request_type.IMPRINT:
            stdout.printf("Content-Type: text/html;charset=us-ascii\n\n");
            stdout.printf(create_imprint_page());
            break;
        default:
            return 1;
    }
    
    return 0;
}

public static void parse_request(string request) {
    request_parts = request.split("/");
    
    //stdout.printf("type: %s", request_parts[REQUEST_OFFSET]);
    
    if (request_parts[REQUEST_OFFSET] == "post") {
    	identifier = request_parts[REQUEST_OFFSET+1]; //post-id
        type = request_type.POST;
    } else if (request_parts[REQUEST_OFFSET] == "image") {
        type = request_type.IMAGE;
        identifier = request_parts[REQUEST_OFFSET+1]; //post-id
        identifier_second = request_parts[REQUEST_OFFSET+2]; //image-id
        filetype = request_parts[REQUEST_OFFSET+2].split(".")[1];
    } else if (request_parts[REQUEST_OFFSET] == "style.css") {
    	identifier = request_parts[REQUEST_OFFSET];
        type = request_type.CSS;
    } else if (request_parts[REQUEST_OFFSET] == "imprint") {
        type = request_type.IMPRINT;
    } else {
    	type = request_type.HOME;
    	if (request_parts.length > REQUEST_OFFSET) {
    		identifier = request_parts[REQUEST_OFFSET]; //pagenum
    	}
    }
}


public static string create_overview_page(int pagesize, int page, int snippet_length) {
	string overview = "";
	
	overview += create_header();
    
    string[] posts = list_directory(BASEPATH_POSTS);
    for(int i=page*pagesize; i<page*pagesize+pagesize && i<posts.length; i++) {
    	overview += "\t<a href=\"%s/post/%s\">\n".printf(BASE_URL, posts[i]);
    	overview += open_content();
    	overview += create_post(posts[i], 200);
    	overview += close_content();
    	overview +=  "</a>\n";
    }
    
    overview += create_navigation(int.parse(identifier?? "0"), posts.length/pagesize+1);
    overview += create_footer();
	
	return overview;
}

public static string create_post_page(string id) {
	string post = "";
	
	post += create_header();
	post += open_content();
    
    post += create_post(id, -1);
    
    post += close_content();
    post += create_footer();
	
	return post;
}


public static string create_post(string id, int length) {
	string content = readFile(BASEPATH_POSTS + "/" + id + "/" + "post.html");
	
	if (content == null) return "";
	
	if (length != -1) {
		content = content.substring(0, length);
	}
	//TODO: 
	//replace links at creation time
	return content;
}


public static string create_navigation(int current_page, int of) {
	string navigation = "";
	
	navigation += "<ul class=\"navigation\">\n";
	
	navigation += "\t<item><a href=\"%s/%d\">&lt;</a></item>\n".printf(BASE_URL, (current_page-1>0)? (current_page-1):0);
	for (int i=0; i<of; i++) {
		navigation += "\t<item><a href=\"%s/%d\">%d</a></item>\n".printf(BASE_URL, i, 1+i);
	}
	navigation += "\t<item><a href=\"%s/%d\">&gt;</a></item>\n".printf(BASE_URL, current_page+1);
	
	navigation += "</ul>\n";
		
	return navigation;
}


public static string create_imprint_page() {
	string page = "";
	
	page += create_header();
	page += open_content();
    
    page += readFile(BASEPATH_STATIC + "/" + "imprint.html");
    
    page += close_content();
    page += create_footer();
	
	return page;
}


public static string create_header() {
	string header = readFile(BASEPATH_STATIC + "/" + "header.html");
	header = header.replace("{title}", BLOG_TITLE);
	header = header.replace("{subtitle}", BLOG_SUBTITLE);
	
	return header;
}


public static string create_footer() {
	return readFile(BASEPATH_STATIC + "/" + "footer.html");
}


public static string open_content() {
	return readFile(BASEPATH_STATIC + "/" + "card_open.html");
}


public static string close_content() {
	return readFile(BASEPATH_STATIC + "/" + "card_close.html");
}


public static string[] list_directory(string dir) {
	string[] list = {};
	
	try {
        var directory = File.new_for_path(dir);

        var enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME, 0);

        FileInfo file_info;
        while ((file_info = enumerator.next_file ()) != null) {
            list += file_info.get_name();
        }

    } catch (Error e) {
        stderr.printf ("Error: %s\n", e.message);
    }
    return list;
}


public static string readFile(string path) {
    string content;
    try {
        FileUtils.get_contents (path, out content);
    } catch (Error e) {
        return "Error 404";
    }
    return content;
}


public static uint8[] readFileBinary(string path) {
    var file = File.new_for_path (path);

    uint8[] content = {};
    
    try {
        int64 file_size = file.query_info ("*", FileQueryInfoFlags.NONE).get_size();
        content = new uint8[file_size];
        file.read().read(content);
    } catch (Error e) {
        error ("%s", e.message);
    }
    
    return content;
}



