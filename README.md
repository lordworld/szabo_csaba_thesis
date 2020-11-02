# szabo_csaba_thesis

Steps to install:
1. download the file 

git clone https://github.com/lordworld/szabo_csaba_thesis.git

2. change the permissions //

cd szabo_csaba_thesis/

chmod 777 ./linux_config.sh

3. run the command.. 

./linux_config.sh

Usage of command: 

${UTIL}: Helps my diploma project to execute configs easier
usage: ${UTIL} COMMAND

Commands:
  linux1			configure my Linux 1
					Details: ...
  linux2			configure my Linux 2
 
Options:
  -h, --help        display this help message.

In case of error:
  git stash push --include-untracked
  git stash drop
  git pull origin main
