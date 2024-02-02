import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2

// comes from nf-test to store json files
params.nf_test_output  = ""

// include dependencies


// include test process
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '/workspaces/readsimulator/./modules/nf-core/custom/dumpsoftwareversions/tests/../main.nf'

// define custom rules for JSON that will be generated.
def jsonOutput =
    new JsonGenerator.Options()
        .excludeNulls()  // Do not include fields with value null..
        .addConverter(Path) { value -> value.toString() } // Custom converter for Path. Only filename
        .build()


workflow {

    // run dependencies
    

    // process mapping
    def input = []
    
                def tool1_version = '''
                TOOL1:
                    tool1: 0.11.9
                '''.stripIndent()

                def tool2_version = '''
                TOOL2:
                    tool2: 1.9
                '''.stripIndent()

                input[0] = Channel.of(tool1_version, tool2_version).collectFile()
                
    //----

    //run process
    CUSTOM_DUMPSOFTWAREVERSIONS(*input)

    if (CUSTOM_DUMPSOFTWAREVERSIONS.output){

        // consumes all named output channels and stores items in a json file
        for (def name in CUSTOM_DUMPSOFTWAREVERSIONS.out.getNames()) {
            serializeChannel(name, CUSTOM_DUMPSOFTWAREVERSIONS.out.getProperty(name), jsonOutput)
        }	  
      
        // consumes all unnamed output channels and stores items in a json file
        def array = CUSTOM_DUMPSOFTWAREVERSIONS.out as Object[]
        for (def i = 0; i < array.length ; i++) {
            serializeChannel(i, array[i], jsonOutput)
        }    	

    }
  
}

def serializeChannel(name, channel, jsonOutput) {
    def _name = name
    def list = [ ]
    channel.subscribe(
        onNext: {
            list.add(it)
        },
        onComplete: {
              def map = new HashMap()
              map[_name] = list
              def filename = "${params.nf_test_output}/output_${_name}.json"
              new File(filename).text = jsonOutput.toJson(map)		  		
        } 
    )
}


workflow.onComplete {

    def result = [
        success: workflow.success,
        exitStatus: workflow.exitStatus,
        errorMessage: workflow.errorMessage,
        errorReport: workflow.errorReport
    ]
    new File("${params.nf_test_output}/workflow.json").text = jsonOutput.toJson(result)
    
}
