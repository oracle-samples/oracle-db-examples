# [SQL Developer](http://www.oracle.com/technetwork/developer-tools/sql-developer/) Examples
## "Simple" User Extensions (XML)
Simple user extensions can be defined to SQL Developer in three different ways.

* **XML files in [sqldeveloper directory]/userextensions**.  
All XML files with "**displays**" as the first element will be processed as *EDITOR*. Those with "**items**" as the first element will be processed as *ACTION*. Those with "**navigator**" as *NAVIGATOR*, others will cause an INFO level log message.

* **Preferences->Database->User Defined Extensions type=ACTION|EDITOR|NAVIGATOR|REPORT**  
This preference page allows specification of fully qualified XML files to load.

* **Packaged in an extension.jar file**  
This allows combining a number of xml definitions together as well as the ability for the user to enable/disable the extension once installed.

*NOTE:* REPORTs are documented in the [SQL Developer User Guide](http://docs.oracle.com/database/sql-developer-4.2/RPTUG/sql-developer-concepts-usage.htm#GUID-2EDED257-9AA5-47F0-A91A-78EEA3556E2C) and will not be discussed here. The [SQL Developer Exchange - Reports](https://apex.oracle.com/pls/apex/f?p=43135:22::::::) & the parent [SQL Developer Examples](../README.md) project may also have more information.

### Contents
 
* [individual](individual)  
Examples for ACTION, EDITOR, NAVIGATOR
  
* [packaged](packaged)  
XML Examples packaged as an extension.jar  

  
* [schema](schema)  
XML schema for the three extension types. Note that the dialogs(ACTION) schema is heavily annotated and has been run through [xsddoc](http://xframe.sourceforge.net/xsddoc/index.html) to produce javadoc-like documentation [here](http://xmlns.oracle.com/sqldeveloper/3_1/dialogs).     