package blackfynn;

import java.util.concurrent.*;
import java.util.ArrayList;
import java.util.List;
import java.net.URL;
import java.io.*;
import java.util.stream.Collectors;
import blackfynn.TsProto.*;
import java.util.stream.*;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import javax.net.ssl.HttpsURLConnection;


public class Request implements Callable<InputStream> {

    private String url;

    public Request(String url) {
        this.url = url;
    }

    public String buildURI(String[] params_a, String api_streaming_host_a,
			   String endpoint_a){
	
	String url;
	url = api_streaming_host_a + endpoint_a + "?";

	// iterate through all of the parameters and build the URL
	//
	int i=0;
	for (String p: params_a){
	    if (i == 0){
		url = url + p + "=";
		i = i + 1;}
	    else {
		url = url + p + "&";
		i = 0;}
	}
	url = url.substring(0, url.length()-1);
	return url;
    }

    public double[][] parseTimeSeriesList(ArrayList<TsProto.Datum> input) {
	DoubleStream myStreamV = input.stream().mapToDouble(TsProto.Datum::getValue);
	double[] arrayV = myStreamV.toArray();
	DoubleStream myStreamT = input.stream().mapToDouble(TsProto.Datum::getTime);

	double[] arrayT = myStreamT.toArray();
	double[][] result = {arrayT, arrayV};

	return result;    
    }

    public List<String> RequestService(String[] params_a, String[] channels_a, String api_streaming_host_a,
			       String endpoint_a) throws Exception{
	ExecutorService executor =
	    Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());

	int i;
	List<Future<InputStream>> futuresArray = new ArrayList<Future<InputStream>>();

	for (String chan: channels_a){
	    params_a[5] = chan;
	    String uri = buildURI(params_a, api_streaming_host_a, endpoint_a);
	    Future<InputStream> response = executor.submit(new Request(uri));
	    futuresArray.add(response);
	}

	// check if all callables are done
	//
	boolean allDone = true;
	for(Future<InputStream> future : futuresArray){
	    allDone &= future.isDone();
	}

	// handle response
	//
	String inputLine;
	List<String> responseArray = new ArrayList<String>();
	for (Future<InputStream> channelResponse : futuresArray){
	    BufferedReader in = new BufferedReader(new InputStreamReader(channelResponse.get()));

	    inputLine = in.readLine();
	    responseArray.add(inputLine);
	    in.close();
	}
	    
	executor.shutdown();
	return responseArray;
    }

    @Override
    public InputStream call() throws Exception {
	URL obj = new URL(url);
	HttpURLConnection con = (HttpURLConnection) obj.openConnection();
	return con.getInputStream();
    }
}
