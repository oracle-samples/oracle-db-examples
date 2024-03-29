
#RUN THIS SCRIPT AT THE PLACE WHERE THE SAGA_WALLET NEEDS TO BE CREATED.
#IN CASE THE SCRIPT WAS EXECUTED ON A DIFFERENT SERVER, EXPORT THE SAGA_WALLET FILES TO A LOCATION ON YOUR MACHINE AND PROVIDE THAT PATH IN APPLICATION.PROPERTIES
#NOTE: THE PATH OF CREATED SAGA WALLET NEEDS TO BE MENTIONED IN APPLICATION.PROPERTIES FILE
#CREATE A WALLET.TXT IN THE SAME FOLDER AS THE SCRIPT, WHICH HOLDS THE PASSWORD FOR THE WALLET.

mkstore -wrl . -create < wallet.txt
mkstore -wrl . -createCredential cdb1_pdb1 admin test < wallet.txt 
mkstore -wrl . -createCredential cdb1_pdb2 admin test < wallet.txt 
mkstore -wrl . -createCredential cdb1_pdb3 admin test < wallet.txt
mkstore -wrl . -createCredential cdb1_pdb4 admin test < wallet.txt
mkstore -wrl . -createCredential inst1 "sys as sysdba" <<SYS_PASSWORD>> < wallet.txt
mkstore -wrl . -listCredential < wallet.txt 
