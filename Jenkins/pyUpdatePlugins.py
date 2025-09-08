#!/usr/bin/env python3

import subprocess
import sys
import json
##import jenkins

JENKINS_URL="https://build-oci.dhsie.hawaii.gov"
JENKINS_USER="chwang"
JENKINS_PASSWORD_OR_TOKEN="h%4\"[r\\"+"LXK|?GO|t"
JENKINS_KEYNAME="NewToken"

##wget https://build-oci.dhsie.hawaii.gov/jnlpJars/jenkins-cli.jar
JENKINS_CLI="./jenkins-cli.jar"


def get_command_output_to_set(command):
    """
    Execute a Linux command and return a set containing the first string 
    (before space or tab) from each line of output.
    
    Args:
        command (str): The Linux command to execute
        
    Returns:
        set: A set containing the first strings from each output line
    """
    try:
        # Execute the command and capture output
        result = subprocess.run(
            command, 
            shell=True, 
            capture_output=True, 
            text=True, 
            check=True
        )
        
        # Process the output
        output_set = set()
        
        # Split output into lines and process each line
        for line in result.stdout.strip().split('\n'):
            if line.strip():  # Skip empty lines
                # Split by space or tab and take the first element
                first_string = line.split()[0] if line.split() else ''
                if first_string:
                    output_set.add(first_string)
        
        return output_set
    
    except subprocess.CalledProcessError as e:
        print(f"Error executing command '{command}': {e}")
        print(f"Error output: {e.stderr}")
        return set()
    except Exception as e:
        print(f"Unexpected error: {e}")
        return set()

def main():
    # Example usage
    if len(sys.argv) > 1:
        # Use command from command line argument
        command = ' '.join(sys.argv[1:])
    else:
        # Default example command
        command = "java -jar jenkins-plugin-manager-*.jar   --list -d /u01/app/jenkins/plugins/"
    print(f"Executing: {command}")
    print("-" * 50)
    # Get the set of first strings
    #------- Get the list of installed plugins
    result_set = get_command_output_to_set(command)
    print(f"Number of unique first strings: {len(result_set)}")
    print(f"10 plugins from sorted output of installed plugins #{len(result_set)}:")
    for item in sorted(list(result_set)[:10]):
        print(f"  {item}")

    print("=" * 50)
    #------- arrange the set of all security warned plugins
    command = "java -jar jenkins-plugin-manager-*.jar -d /u01/app/jenkins/plugins/ --view-all-security-warnings"
    v_set = get_command_output_to_set_explicit(command)
    print(f"Executing: {command}")
    print("-" * 50)
    # Display results
    print(f"Found {len(v_set)} unique warned plugins")
    print(f"10 plugins from sorted output of installed plugins #{len(v_set)}:")
    for item in sorted(list(v_set)[:10]):  # Show first 10
        print(f"  {item}")
    print("=" * 50)

    #------- arrange the string of target plugins
    intersection = result_set.intersection(v_set)
    print(f"Number of target plugins: {len(intersection)}")
    strArg = ' '.join(str(item+':1') for item in sorted(intersection))
    strArgPlg = ' '.join(str(item) for item in sorted(intersection))
    strArgConcat = '__'.join(str(item+'__') for item in sorted(intersection))
    ##print(f"  {strArgConcat}")
    ##print("-" * 50)
    print(f"  {strArgPlg}")

    print("=" * 50)
    #------- arrange the string of target plugins having updates
    command = "java -jar jenkins-plugin-manager-*.jar  --available-updates -p " + strArg
    t_set = get_command_output_to_set(command)
    print(f"Executing command: {command}")
    print("-" * 50)
    # Display results
    print(f"Found warned and available plugins")
    strArgConcat = ""
    for item in sorted(t_set):  
        if item !="Available":
            print(f"  {item}")
            strArgConcat = strArgConcat + "____" + item

    ##print(f"=====> {strArgConcat}")

    print("=" * 50)
    #------- check the existing access tokens
    command = "./shGetExistingTokens.sh"
    tokens=call_bash(command , " ")
    print("Existing Tokens:")
    print(f"{tokens}")

    print("=" * 50)
    #------- remove the existing access tokens
    data = json.loads(tokens)
    for key, value in data['chwang'].items():
        if value == JENKINS_KEYNAME:
           # print(f"{key}: {value}")
           co = "./shDeleteToken.sh"
           print(f"Deleting ({JENKINS_USER})  [{value}]:[{key}]")
           Dele = call_bash(co, JENKINS_USER+" "+value)
           print(f"   > {Dele}")

    print("=" * 50)
    #------- install the plugins
    command = "./shInstallPlugin.sh " + strArgConcat
    command = "./shInstallPlugin.sh " + "ant____batch-task"
    print("Installing Plugins:")
    final=call_bash(command , " ")
    print(f"{final}")



def call_bash(command, arg):
    command = command + " " + arg
    try:
        result = subprocess.run(
            command, 
            shell=True, 
            capture_output=True, 
            text=True, 
            check=True
        )
        #print(f"  {result}")
        return result.stdout
    except Exception as e:
        print(f"Unexpected error: {e}")
        return False

# Alternative function using more explicit splitting for space/tab
def get_command_output_to_set_explicit(command):
    """
    Alternative version that explicitly handles space and tab separation.
    """
    try:
        result = subprocess.run(
            command, 
            shell=True, 
            capture_output=True, 
            text=True, 
            check=True
        )
        
        output_set = set()
        
        for line in result.stderr.strip().split('\n'):
            if line.strip():
                # Find first space or tab
                space_pos = line.find(' ')
                tab_pos = line.find('\t')
                
                # Get the position of the first delimiter (space or tab)
                if space_pos == -1:
                    delimiter_pos = tab_pos
                elif tab_pos == -1:
                    delimiter_pos = space_pos
                else:
                    delimiter_pos = min(space_pos, tab_pos)
                
                # Extract first string
                if delimiter_pos == -1:
                    # No space or tab found, entire line is the first string
                    first_string = line.strip()
                else:
                    first_string = line[:delimiter_pos].strip()
                
                if first_string:
                    output_set.add(first_string)
        
        return output_set
    
    except subprocess.CalledProcessError as e:
        print(f"Error executing command '{command}': {e}")
        print(f"Error output: {e.stderr}")
        return set()
    except Exception as e:
        print(f"Unexpected error: {e}")
        return set()

# function using more explicit splitting for space/tab
def asdf(command):
    """
    Alternative version that explicitly handles space and tab separation.
    """
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            check=True
        )

        output_set = set()

        for line in result.stderr.strip().split('\n'):
            if line.strip():
                # Find first space or tab
                space_pos = line.find(' ')
                tab_pos = line.find('\t')

                # Get the position of the first delimiter (space or tab)
                if space_pos == -1:
                    delimiter_pos = tab_pos
                elif tab_pos == -1:
                    delimiter_pos = space_pos
                else:
                    delimiter_pos = min(space_pos, tab_pos)

                # Extract first string
                if delimiter_pos == -1:
                    # No space or tab found, entire line is the first string
                    first_string = line.strip()
                else:
                    first_string = line[:delimiter_pos].strip()

                if first_string:
                    output_set.add(first_string)

        return output_set

    except subprocess.CalledProcessError as e:
        print(f"Error executing command '{command}': {e}")
        print(f"Error output: {e.stderr}")
        return set()
    except Exception as e:
        print(f"Unexpected error: {e}")
        return set()

if __name__ == "__main__":
    main()
    
    # Example of using the explicit version
    #print("\n" + "="*50)
    #print("Using explicit space/tab handling:")
    #example_set = get_command_output_to_set_explicit("ps aux")
    #print(f"Found {len(example_set)} unique process owners/commands")
    #for item in sorted(list(example_set)[:10]):  # Show first 10
        #print(f"  {item}")
