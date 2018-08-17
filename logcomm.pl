#!/usr/local/bin/perl -w
#------------------------------------------------------------------------------
# Licensed Materials - Property of IBM (C) Copyright IBM Corp. 2010, 2010
# All Rights Reserved US Government Users Restricted Rights - Use, duplication
# or disclosure restricted by GSA ADP Schedule Contract with IBM Corp
#------------------------------------------------------------------------------

#  perl agentaud.pl diagnostic_log
#
#  Create a report on agent row results from
#  kpxrpcrq tracing
#
#  john alvord, IBM Corporation, 22 December 2014
#  jalvord@us.ibm.com
#
# tested on Windows Activestate 5.20.1
#
# $DB::single=2;   # remember debug breakpoint

$gVersion = 0.50000;
$gWin = (-e "C:/") ? 1 : 0;       # determine Windows versus Linux/Unix for detail settings

## Todos

## Todos
#  Handle Agent side historical traces - needs definition and work.

#          Data row is filtered
# (54931626.0DA9-11:kdsflt1.c,1427,"FLT1_FilterRecord") Entry
# (54931626.0DAC-11:kdsflt1.c,1464,"FLT1_FilterRecord") Exit: 0x1      <=== row fails filter
# (54931625.023C-3:kdsflt1.c,1464,"FLT1_FilterRecord") Exit: 0x0       <=== row passes filter

#         Potential row data is produced - including sitname
# (54931626.0DAE-11:kraaevxp.cpp,501,"CreateSituationEvent") *EV-INFO: Input event: obj=0x1111FA530, type=5, excep=0, numbRow=1, rowData=0x110ADF640, status=0, sitname="UNIX_LAA_Bad_su_to_root_Warning"
# (54931626.0DB2-11:kraaevxp.cpp,562,"CreateSituationEvent") *EV-INFO: Use request <1111FA530> handle <294650831> element <111167790>
# (54931626.0DB4-11:kraaevxp.cpp,414,"EnqueueEventWork") *EV-INFO: Enqueue event work element 111167790 to Dispatcher
# (54931626.0DB5-11:kraaprdf.cpp,228,"CheckForException") Exit: 0x0
# (54931626.0DB7-11:kraulleb.cpp,194,"AddData") Exit: 0x0
# (unit:kraaevxp,Entry="CreateSituationEvent" detail er)
#
#         No data is sent
# (54931626.0DBB-11:kraadspt.cpp,868,"sendDataToProxy") Entry
# (54931626.0DBD-11:kraadspt.cpp,955,"sendDataToProxy") Exit

#         Some data is sent
# (54931626.0DBB-11:kraadspt.cpp,868,"sendDataToProxy") Entry
# (54931625.04D0-3:kraadspt.cpp,889,"sendDataToProxy") Sending 14 rows for UNIX_LAA_Log_Size_Warning KUL.ULMONLOG, <722472833,294650830>.
# (54931626.0DBD-11:kraadspt.cpp,955,"sendDataToProxy") Exit

## !5A9E41FB.0000!========================>  IBM Tivoli RAS1 Service Log  <========================
## +5A9E41FB.0000      System Name: USRD12ZDU2005               Process ID: 1684
## +5A9E41FB.0000     Program Name: k5pagent                     User Name: SYSTEM
## +5A9E41FB.0000        Task Name: k5pagent                   System Type: Windows;6.2
## +5A9E41FB.0000   MAC1_ENV Macro: 0xC112                      Start Date: 2018/03/06
## +5A9E41FB.0000       Start Time: 07:23:39                     CPU Count: 2
## +5A9E41FB.0000        Page Size: 4K                         Phys Memory: 4096M
## +5A9E41FB.0000      Virt Memory: 134217728M                  Page Space: 4800M
## +5A9E41FB.0000   UTC Start Time: 5a9e41fb                      ITM Home: C:\IBM\ITM
## +5A9E41FB.0000      ITM Process: usrd12zdu2005_5p
## +5A9E41FB.0000    Service Point: system.usrd12zdu2005_5p

## (5A9E41FD.0055-698:kraarreg.cpp,3932,"IRA_SetConnectCMSLIST") *INFO: 01 IP.SPIPE:146.89.140.75
## (5A9E41FD.0056-698:kraarreg.cpp,3932,"IRA_SetConnectCMSLIST") *INFO: 02 IP.PIPE:146.89.140.75
## (5A9E41FD.0057-698:kraarreg.cpp,3946,"IRA_SetConnectCMSLIST") *INFO: Primary TEMS set to <IP.SPIPE:146.89.140.75> host <146.89.140.75>
## (5A9E41FE.0081-7BC:kdepnpc.c,138,"KDEP_NewPCB") 146.89.140.75: D2900386, KDEP_pcb_t @ 3760F20 created

## (5AA2E3F5.0004-13E0:kdepnpc.c,138,"KDEP_NewPCB") 146.89.140.76: D2F00373, KDEP_pcb_t @ 37618E0 created
## (5AAB62B3.0004-1BA0:kdepnpc.c,138,"KDEP_NewPCB") 146.89.140.76: D310034F, KDEP_pcb_t @ 3760D80 created

## (5AA6520D.0000-7DC:kdepdpc.c,62,"KDEP_DeletePCB") D2F00373: KDEP_pcb_t deleted



## (5AA2E3F4.0002-13E0:kdepnpc.c,138,"KDEP_NewPCB") 146.89.140.75: D2D0037C, KDEP_pcb_t @ 3761330 created
## (5AA2E3F5.0000-13E0:kdepdpc.c,62,"KDEP_DeletePCB") D2D0037C: KDEP_pcb_t deleted
## (5AA2E3F5.0004-13E0:kdepnpc.c,138,"KDEP_NewPCB") 146.89.140.76: D2F00373, KDEP_pcb_t @ 37618E0 created
## (5AA2E3F5.0005-1A34:kdebpli.c,211,"KDEBP_Listen") pipe 2 assigned: PLE=1F4F9F0, count=1, hMon=D2B00381

## (5AA31B32.0001-9F0:kdepnpc.c,138,"KDEP_NewPCB") 146.89.140.75: D470034C, KDEP_pcb_t @ 375FBA0 created
## (5AA31B33.0000-9F0:kdepdpc.c,62,"KDEP_DeletePCB") D470034C: KDEP_pcb_t deleted


## (5AA1C09A.0001-11F0:khdxbase.cpp,339,"setError")
## +5AA1C09A.0001  ERROR MESSAGE: "Unable to open Metafile "C:\IBM\ITM\TMAITM~1\logs\History\K5P\K5PMANAGED.hdr" "
## (5AA1C09A.0002-11F0:khdxbase.cpp,336,"setError")
## +5AA1C09A.0002  Error Type= CTX_MetafileNotfound


# CPAN packages used
use Data::Dumper;               # debug
use warnings::unused; # debug used to check for unused variables
use Time::Local;
use POSIX qw{strftime};


my $start_date = "";
my $start_time = "";
my $local_diff = -1;

# This is a typical log scraping program. The log data looks like this
#
# Distributed with a situation:
# (4D81D817.0000-A17:kpxrpcrq.cpp,749,"IRA_NCS_Sample") Rcvd 1 rows sz 220 tbl *.RNODESTS req HEARTBEAT <219213376,1892681576> node <Primary:INMUM01B2JTP01:NT>
#   Interesting failure cases
# (4FF79663.0003-4:kpxrpcrq.cpp,826,"IRA_NCS_Sample") Sample <665885373,2278557540> arrived with no matching request.
# (4FF794A9.0001-28:kpxrpcrq.cpp,802,"IRA_NCS_Sample") RPC socket change detected, initiate reconnect, node thp-gl-04:KUX!
#
# Distributed without situation
# (4D81D81A.0000-A1A:kpxrpcrq.cpp,749,"IRA_NCS_Sample") Rcvd 1 rows sz 816 tbl *.UNIXOS req  <418500981,1490027440> node <evoapcprd:KUX>
#
# z/OS RKLVLOG lines contain the same information but often split into two lines
# and the timestamp is in a different form.
#  2011.080 14:53:59.78 (005E-D61DDF8B:kpxrpcrq.cpp,749,"IRA_NCS_Sample") Rcvd 1 rows sz 220 tbl *.RNODESTS req HEARTBEAT <565183706,5
#  2011.080 14:53:59.79 65183700> node <IRAM:S8CMS1:SYS:STORAGE         >
#
# the data is identical otherwise
#
#  Too Big message
#   (4D75475E.0001-B00:kpxreqds.cpp,1695,"buildThresholdsFilterObject") Filter object too big (39776 + 22968),Table FILEINFO Situation SARM_UX_FileMonitoring2_Warn.
#
#  SOAP IP address
#  (4D9633C2.0010-11:kshdhtp.cpp,363,"getHeaderValue") Header is <ip.ssl:#10.41.100.21:38317>
#
#  SOAP SQL
#  (4D9633C2.0020-11:kshreq.cpp,881,"buildSQL") Using pre-built SQL: SELECT NODE, AFFINITIES, PRODUCT, VERSION, RESERVED, O4ONLINE FROM O4SRV.INODESTS
#  (4D9633C3.0021-11:kshreq.cpp,1307,"buildSQL") Using SQL: SELECT CLCMD,CLCMD2,CREDENTIAL,CWD,KEY,MESSAGE,ACTSECURE,OPTIONS,RESPFILE,RUNASUSER,RUNASPWD,REQSTATUS,ACTPRTY,RESULT,ORIGINNODE FROM O4SRV.CLACTRMT WHERE  SYSTEM.PARMA("NODELIST", "swdc-risk1csc0:KUX", 18) AND  CLCMD =  N"/opt/IBM/custom/ChangeTEMS_1.00.sh PleaseReturnZero"
#
# To manage the differences, a state engine is used.
#  When set to 0 based on absence of -z option, the lines are processed directly
#
#  For RKLVLOG case the state is set to 1 at outset.
#  When 1, the first line is examined. RKLVLOGs can be in two forms. When
#  collected as a SYSOUT file, there is an initial printer control character
#  of "1" or " ", a printer control character. In that case all the lines have
#  a printer control character of blank. If recogonized a variable $offset
#  is set to value o1.
#
#  The second form is when the RKLVLOG is written directly to a disk file.
#  In this case the printer control characters are absent. For that case the
#  variable $offset is set to 0. When getting the data, $offset is used
#  calculations.
#
#  After state 1, state 2 is entered.
#
# When state=2, the input record is checked for the expected form of trace.
# If not, the next record is processed. If found, the partial line
# is captured and the state is set to 3. The timestamp is also captured.
# then the next record is processed.
#
# When state=3, the second part of the data is captured. The data is assembled
# as if it was a distributed record. The timestamp is converted to the
# distributed timestamp. The state is set to 2 and then the record is processed.
# Sometimes we don't know if there is a continuation or not. Thus we usually
# keep the prior record and add to it if the next one is not in correct form.
#
# Processing is typical log scraping. The target is identified, an associative
# array is used to look up prior cases, and the data is recorded. At the end
# the accumulated data is printed to standard output.

# pick up parameters and process

my $opt_z;
my $opt_zop;
my $opt_logpath;
my $full_logfn;
my $opt_v;
my $opt_vv;
my $opt_cmdall;                                  # show all commands

sub gettime;                             # get time
sub sec2ltime;
sub do_rpt;


# following hashtable is a backup for calculating table lengths.
# Windows, Linux, Unix tables only at the moment

my %kdemsgx = (
   '00000000' => ["","KDE1_STC_OK"],
   '1DE00000' => ["","KDE1_STC_CANTBIND"],
   '1DE00001' => ["","KDE1_STC_NOMEMORY"],
   '1DE00002' => ["","KDE1_STC_TOOMANY"],
   '1DE00003' => ["","KDE1_STC_BADRAWNAME"],
   '1DE00004' => ["","KDE1_STC_BUFTOOLARGE"],
   '1DE00005' => ["","KDE1_STC_BUFTOOSMALL"],
   '1DE00006' => ["","KDE1_STC_ENDPOINTUNAVAILABLE"],
   '1DE00007' => ["","KDE1_STC_NAMEUNAVAILABLE"],
   '1DE00008' => ["","KDE1_STC_NAMENOTFOUND"],
   '1DE00009' => ["","KDE1_STC_CANTGETLOCALNAME"],
   '1DE0000A' => ["","KDE1_STC_SOCKETOPTIONERROR"],
   '1DE0000B' => ["","KDE1_STC_DISCONNECTED"],
   '1DE0000C' => ["","KDE1_STC_INVALIDNAMEFORMAT"],
   '1DE0000D' => ["","KDE1_STC_IOERROR"],
   '1DE0000E' => ["","KDE1_STC_NOTLISTENING"],
   '1DE0000F' => ["","KDE1_STC_NOTREADY"],
   '1DE00010' => ["","KDE1_STC_INVALIDFAMILY"],
   '1DE00011' => ["","KDE1_STC_INTERNALERROR"],
   '1DE00012' => ["","KDE1_STC_NOTEQUAL"],
   '1DE00013' => ["","KDE1_STC_INVALIDLENGTH"],
   '1DE00014' => ["","KDE1_STC_FUNCTIONUNAVAILABLE"],
   '1DE00015' => ["","KDE1_STC_ARGUMENTINCONSISTENCY"],
   '1DE00016' => ["","KDE1_STC_PROTOCOLERROR"],
   '1DE00017' => ["","KDE1_STC_MISSINGINFORMATION"],
   '1DE00018' => ["","KDE1_STC_DUPLICATEINFORMATION"],
   '1DE00019' => ["","KDE1_STC_ARGUMENTRANGE"],
   '1DE0001A' => ["","KDE1_STC_THREADSREQUIRED"],
   '1DE0001B' => ["syntax error",                                                              "KDE1_STC_SYNTAXERROR"],
   '1DE0001C' => ["KDE1_tvt_t deref member inconsistency",                                     "KDE1_STC_DEREFVALUEINCONSISTENT"],
   '1DE0001D' => ["protocol-name/protseq inconsistent",                                        "KDE1_STC_PROTSEQINCONSISTENT"],
   '1DE0001E' => ["cant create sna conversation",                                              "KDE1_STC_CANTCREATECONVERSATION"],
   '1DE0001F' => ["cant set sna synclevel",                                                    "KDE1_STC_CANTSETSYNCLEVEL"],
   '1DE00020' => ["cant set sna partner lu name",                                              "KDE1_STC_CANTSETPARTNERLUNAME"],
   '1DE00021' => ["cant set sna mode name",                                                    "KDE1_STC_CANTSETMODENAME"],
   '1DE00022' => ["cant set sna tpname",                                                       "KDE1_STC_CANTSETTPNAME"],
   '1DE00023' => ["cant allocate sna conversation",                                            "KDE1_STC_CANTALLOCATECONVERSATION"],
   '1DE00024' => ["cant create sna local lu",                                                  "KDE1_STC_CANTCREATELOCALLU"],
   '1DE00025' => ["cant define sna local tp",                                                  "KDE1_STC_CANTDEFINELOCALTP"],
   '1DE00026' => ["protocol method limit exceeded",                                            "KDE1_STC_TOOMANYMETHODS"],
   '1DE00027' => ["interface specification is invalid",                                        "KDE1_STC_PROTSEQINTERFACEINVALID"],
   '1DE00028' => ["method specification is invalid",                                           "KDE1_STC_PROTSEQMETHODINVALID"],
   '1DE00029' => ["protocol specification is invalid",                                         "KDE1_STC_PROTSEQPROTOCOLINVALID"],
   '1DE0002A' => ["family specification is invalid",                                           "KDE1_STC_PROTSEQFAMILYINVALID"],
   '1DE0002B' => ["side information profile name too long",                                    "KDE1_STC_SIPNAMETOOLONG"],
   '1DE0002C' => ["no server bindings available",                                              "KDE1_STC_SERVERNOTBOUND"],
   '1DE0002D' => ["buffer is reserved",                                                        "KDE1_STC_RESERVEDBUFFER"],
   '1DE0002E' => ["server is not listening",                                                   "KDE1_STC_SERVERNOTLISTENING"],
   '1DE0002F' => ["buffer is not valid",                                                       "KDE1_STC_INVALIDBUFFER"],
   '1DE00030' => ["the requested endpoint is in use",                                          "KDE1_STC_ENDPOINTINUSE"],
   '1DE00031' => ["all endpoints in the pool are in use",                                      "KDE1_STC_ENDPOINTPOOLEXHAUSTED"],
   '1DE00032' => ["invalid circuit handle",                                                    "KDE1_STC_BADCIRCUITHANDLE"],
   '1DE00033' => ["circuit handle is not currently in use",                                    "KDE1_STC_HANDLENOTINUSE"],
   '1DE00034' => ["operation was cancelled",                                                   "KDE1_STC_OPERATIONCANCELLED"],
   '1DE00035' => ["SNA Network ID doesn't match system definition",                            "KDE1_STC_NETIDMISMATCH"],
   '1DE00036' => ["Function must be performed prior to bind of setup data",                    "KDE1_STC_SETUPALREADYBOUND"],
   '1DE00037' => ["No transport providers are registered",                                     "KDE1_STC_NOTRANSPORTSREGISTERED"],
   '1DE00038' => ["Configuration handle invalid",                                              "KDE1_STC_BADCONFIGHANDLE"],
   '1DE00039' => ["unable to query local node information",                                    "KDE1_STC_CANTQUERYLOCALNODE"],
   '1DE0003A' => ["vector count out of range",                                                 "KDE1_STC_VECTORCOUNTINVALID"],
   '1DE0003B' => ["duplicate vector code encountered",                                         "KDE1_STC_DUPLICATEVECTOR"],
   '1DE0003C' => ["a required XID buffer was not received successfully",                       "KDE1_STC_RECEIVEXIDFAILURE"],
   '1DE0003D' => ["invalid XID buffer format",                                                 "KDE1_STC_INVALIDXIDBUFFER"],
   '1DE0003E' => ["unable to create pipe infrastructure",                                      "KDE1_STC_PIPECREATIONFAILED"],
   '1DE0003F' => ["target endpoint is not bound","KDE1_STC_ENDPOINTNOTBOUND"],
   '1DE00040' => ["target endpoint queueing limit reached","KDE1_STC_RECEIVELIMITEXCEEDED"],
   '1DE00041' => ["configuration keyword not found","KDE1_STC_KEYWORDNOTFOUND"],
   '1DE00042' => ["endpoint value not supported","KDE1_STC_INVALIDENDPOINT"],
   '1DE00043' => ["KDE_TRANSPORT error caused some values of this keyword to be ignored","KDE1_STC_KEYWORDVALUEIGNORED"],
   '1DE00044' => ["streaming packet synchronization lost","KDE1_STC_PACKETSYNCLOST"],
   '1DE00045' => ["connection procedure failed","KDE1_STC_CONNECTIONFAILURE"],
   '1DE00046' => ["unable to create any more interfaces","KDE1_STC_INTERFACELIMITREACHED"],
   '1DE00047' => ["transport provider is unavailable for use","KDE1_STC_TRANSPORTDISABLED"],
   '1DE00048' => ["transport provider failed to register any interfaces","KDE1_STC_NOINTERFACESREGISTERED"],
   '1DE00049' => ["transport provider registered too many interfaces","KDE1_STC_INTERFACELIMITEXCEEDED"],
   '1DE0004A' => ["unable to negotiate a secure connection using SSL","KDE1_STC_SSLFAILURE"],
   '1DE0004B' => ["unable to contact ephemeral endpoint","KDE1_STC_EPHEMERALENDPOINT"],
   '1DE0004C' => ["unable to perform request without a transport correlator","KDE1_STC_NEEDTRANSPORTCORRELATOR"],
   '1DE0004D' => ["transport correlator invalid","KDE1_STC_INVALIDTRANSPORTCORRELATOR"],
   '1DE0004E' => ["address not accessible","KDE1_STC_ADDRESSINACCESSIBLE"],
   '1DE0004F' => ["secure endpoint unavailable","KDE1_STC_SECUREENDPOINTUNAVAILABLE"],
   '1DE00050' => ["ipv6 support unavailable","KDE1_STC_IPV6UNAVAILABLE"],
   '1DE00051' => ["z/OS TTLS support not available","KDE1_STC_TTLSUNAVAILABLE"],
   '1DE00052' => ["z/OS TTLS connection not established","KDE1_STC_TTLSNOTESTABLISHED"],
   '1DE00053' => ["z/OS TTLS connection policy not application controlled","KDE1_STC_TTLSNOTAPPCTRL"],
   '1DE00054' => ["Send request was incomplete","KDE1_STC_INCOMPLETESEND"],
   '1DE00055' => ["operating in originate-only ephemeral mode","KDE1_STC_ORIGONLYEPHMODE"],
   '1DE00056' => ["socket file descriptor out of range of select mask size","KDE1_STC_SOCKETFDTOOLARGE"],
   '1DE00057' => ["unable to create object of type pthread_mutex_t","KDE1_STC_MUTEXERROR"],
   '1DE00058' => ["unable to create object of type pthread_cond_t","KDE1_STC_CONDITIONERROR"],
   '1DE00059' => ["gateway element must have a name attribute","KDE1_STC_GATEWAYNAMEREQUIRED"],
   '1DE0005A' => ["gateway name already in use","KDE1_STC_GATEWAYNAMEEXISTS"],
   '1DE0005B' => ["invalid numeric attribute","KDE1_STC_XMLATTRNONNUMERIC"],
   '1DE0005C' => ["numeric attribute value out of range","KDE1_STC_XMLATTROUTOFRANGE"],
   '1DE0005D' => ["required attribute not supplied","KDE1_STC_XMLATTRREQUIRED"],
   '1DE0005E' => ["attribute keyword not recognized","KDE1_STC_XMLATTRKEYWORDINVALID"],
   '1DE0005F' => ["attribute keyword is ambiguous","KDE1_STC_XMLATTRKEYWORDAMBIG"],
   '1DE00060' => ["gateway configuration file not found","KDE1_STC_GATEWAYCONFIGFILENOTFOUND"],
   '1DE00061' => ["syntax error in XML document","KDE1_STC_XMLDOCUMENTERROR"],
   '1DE00062' => ["listening bindings require an endpoint number","KDE1_STC_ENDPOINTREQUIRED"],
   '1DE00063' => ["thread creation procedure failed","KDE1_STC_CREATETHREADFAILED"],
   '1DE00064' => ["nested downstream definitions not supported","KDE1_STC_DOWNSTREAMNESTING"],
   '1DE00065' => ["upstream interfaces require one or more downstream interfaces","KDE1_STC_NODOWNSTREAMINTERFACES"],
   '1DE00066' => ["invalid socket option","KDE1_STC_SOCKETOPTIONINVALID"],
   '1DE00067' => ["Windows event object error","KDE1_STC_WSAEVENTERROR"],
   '1DE00068' => ["simultaneous per socket wait limit exceeded","KDE1_STC_TOOMANYWAITS"],
   '1DE00069' => ["XML document did not contain TEP gateway configuration","KDE1_STC_NOGATEWAYDEFINITIONS"],
   '1DE0006A' => ["Socket monitor handle invalid","KDE1_STC_MONITORHANDLEINVALID"],
   '1DE0006B' => ["Connection limit reached","KDE1_STC_CONNECTIONLIMITREACHED"],
   '1DE0006C' => ["Gateway contains no zone elements","KDE1_STC_NOZONESINGATEWAY"],
   '1DE0006D' => ["Zone contains no interface elements","KDE1_STC_NOINTERFACESINZONE"],
   '1DE0006E' => ["Connection ID invalid","KDE1_STC_BADCONNECTIONID"],
   '1DE0006F' => ["Service name invalid","KDE1_STC_BADSERVICENAME"],
   '1DE00070' => ["Pipe handle invalid","KDE1_STC_BADPIPEHANDLE"],
   '1DE00071' => ["Connection markup is required","KDE1_STC_NEEDCONNECTIONTAG"],
   '1DE00072' => ["Monitor close in progress","KDE1_STC_MONITORCLOSING"],
   '1DE00073' => ["Socket not detached from monitor","KDE1_STC_MONITORDETACHERROR"],
   '1DE00074' => ["datastream integrity lost","KDE1_STC_DATASTREAMINTEGRITYLOST"],
   '1DE00075' => ["retry limit exceeded","KDE1_STC_RETRYLIMITEXCEEDED"],
   '1DE00076' => ["pipe not in required state","KDE1_STC_WRONGPIPESTATE"],
   '1DE00077' => ["Local binding is not unique","KDE1_STC_DUPLICATELOCALBINDING"],
   '1DE00078' => ["PIPE packet header missing or invalid","KDE1_STC_PACKETHEADERINVALID"],
   '1DE00079' => ["XML element inconsistency","KDE1_STC_XMLELEMENTINCONSISTENCY"],
   '1DE0007A' => ["Endpoint security negotiation failed","KDE1_STC_ENDPOINTNOTSECURE"],
   '1DE0007B' => ["file descriptor limit reached","KDE1_STC_FILEDESCRIPTORSEXHAUSTED"],
   '1DE0007C' => ["invalid link handle","KDE1_STC_BADLINKHANDLE"],
   '1DE0007D' => ["expired link handle","KDE1_STC_EXPIREDLINKHANDLE"],
   '1DE0007E' => ["RFC1831 record not complete","KDE1_STC_REPLYRECORDSPLIT"],
   '1DE0007F' => ["RFC1831 record too long","KDE1_STC_REPLYTOOLONG"],
   '1DE00080' => ["RFC1831 stream contains extra data","KDE1_STC_REPLYSTREAMERROR"],
   '1DE00081' => ["RFC1831 reply expected","KDE1_STC_REPLYEXPECTED"],
   '1DE00082' => ["RFC1831 request not accepted","KDE1_STC_REMOTEREQUESTREJECTED"],
   '1DE00083' => ["RFC1831 request failed","KDE1_STC_REMOTEREQUESTFAILED"],
   '1DE00084' => ["RFC1833 portmap request error","KDE1_STC_PORTMAPREQUESTERROR"],
              );

my %commenvx = (
                 'CT_CMSLIST' => 1,
                 'CTIRA_RECONNECT_WAIT' => 1,
                 'CTIRA_MAX_RECONNECT_TRIES' => 1,
                 'KDE_TRANSPORT' => 1,
                 'CTIRA_PRIMARY_FALLBACK_INTERVAL' => 1,
                 'KDEB_INTERFACELIST_IPV6' => 1,
                 'KDEB_INTERFACELIST' => 1,
                 'CTIRA_HEARTBEAT' => 1,
              );

my %porterrx;

my $rptkey;

my %advrptx = ();

my $cnt = -1;
my @oline = ();
my $hdri = -1;                               # some header lines for report
my @hdr = ();                                #
my $advisori = -1;
my @advisor = ();
my %timelinex;
my $timeline_start;
my %timelinexx;
my %envx;
my %rpcrunx;
my @dlogfiles;
my @seg = ();
my @seg_time = ();
my $segi = -1;
my $segp = -1;
my $segcur = "";
my $segline;
my $segmax = 0;



#  following are the nominal values. These are used to generate an advisories section
#  that can guide usage of the Workload report. These can be overridden by the agentaud.ini file.

my $opt_nohdr;                               # when 1 no headers printed
my $opt_objid;                               # when 1 print object id
my $opt_o;                                   # when defined filename of report file
my $opt_tsit;                                # when defined debug testing sit
my $opt_slot;                                # when defined specify history slots, default 60 minutes
my $opt_pc;
my $opt_allenv;                              # when 1 dump all environment variables
my $opt_allinv;                              # when 1 dump all environment variables
my $opt_merge;

my $arg_start = join(" ",@ARGV);
$hdri++;$hdr[$hdri] = "Runtime parameters: $arg_start";

while (@ARGV) {
   if ($ARGV[0] eq "-h") {
      &GiveHelp;                        # print help and exit
   }
   if ($ARGV[0] eq "-z") {
      $opt_z = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-cmdall") {
      $opt_cmdall = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-nohdr") {
      $opt_nohdr = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-objid") {
      $opt_objid = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-tsit") {
      shift(@ARGV);
      $opt_tsit = shift(@ARGV);
      die "Option -tsit with no test situation set" if !defined $opt_tsit;
   } elsif ($ARGV[0] eq "-pc") {
      shift(@ARGV);
      $opt_pc = shift(@ARGV);
      die "Option -pc with no product code set" if !defined $opt_pc;
   } elsif ($ARGV[0] eq "-o") {
      shift(@ARGV);
      if (defined $ARGV[0]) {
         if (substr($ARGV[0],0,1) ne "-") {
            $opt_o = shift(@ARGV);
         }
      }
   } elsif ($ARGV[0] eq "-zop") {
      shift(@ARGV);
      $opt_zop = shift(@ARGV);
      die "-zop output specified but no file found\n" if !defined $opt_zop;
   } elsif ($ARGV[0] eq "-slot") {
      shift(@ARGV);
      $opt_slot = shift(@ARGV);
      die "slot specified but no slot time found\n" if !defined $opt_slot;
      die "slot must be an integer 1 to 60 minutes" if ($opt_slot < 1) or ($opt_slot > 60);
   } elsif ($ARGV[0] eq "-v") {
      $opt_v = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-allenv") {
      $opt_allenv = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-allinv") {
      $opt_allinv = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-vv") {
      $opt_vv = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-logpath") {
      shift(@ARGV);
      $opt_logpath = shift(@ARGV);
      die "logpath specified but no path found\n" if !defined $opt_logpath;
   } else {
      $logfn = shift(@ARGV);
      die "log file name not defined\n" if !defined $logfn;
   }
}


die "logpath and -z must not be supplied together\n" if defined $opt_z and defined $opt_logpath;

if (!defined $opt_logpath) {$opt_logpath = "";}
if (!defined $logfn) {$logfn = "";}
if (!defined $opt_z) {$opt_z = 0;}
if (!defined $opt_zop) {$opt_zop = ""}
if (!defined $opt_cmdall) {$opt_cmdall = 0;}
if (!defined $opt_nohdr) {$opt_nohdr = 0;}
if (!defined $opt_objid) {$opt_objid = 0;}
if (!defined $opt_tsit) {$opt_tsit = "ZZZZZZZZZ";}
if (!defined $opt_o) {$opt_o = "logcomm.csv";}
if (!defined $opt_slot) {$opt_slot = 60;}
if (!defined $opt_v) {$opt_v = 0;}
if (!defined $opt_allenv) {$opt_allenv = 0;}
if (!defined $opt_allinv) {$opt_allinv = 0;}
if (!defined $opt_allinv) {$opt_allinv = 0;}
if (!defined $opt_vv) {$opt_vv = 0;}
if (!defined $opt_pc) {$opt_pc = "";}
$opt_merge = $opt_allinv;

open( ZOP, ">$opt_zop" ) or die "Cannot open zop file $opt_zop : $!" if $opt_zop ne "";


if ($gWin == 1) {
   $pwd = `cd`;
   chomp($pwd);
   if ($opt_logpath eq "") {
      $opt_logpath = $pwd;
   }
   $opt_logpath = `cd $opt_logpath & cd`;
   chomp($opt_logpath);
   chdir $pwd;
} else {
   $pwd = `pwd`;
   chomp($pwd);
   if ($opt_logpath eq "") {
      $opt_logpath = $pwd;
   } else {
      $opt_logpath = `(cd $opt_logpath && pwd)`;
      chomp($opt_logpath);
   }
   chdir $pwd;
}


$opt_logpath .= '/';
$opt_logpath =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments

die "logpath or logfn must be supplied\n" if !defined $logfn and !defined $opt_logpath;

# Establish nominal values for the Advice Summary section

my $pattern;
my @results = ();
my $inline;
my $logbase;
my %todo = ();     # associative array of names and first identified timestamp
my $skipzero = 0;

if ($logfn eq "") {
   $pattern = "_ms(_kdsmain)?\.inv";
#   $pattern = "_" . $opt_pc . "_k" . $opt_pc . "agent\.inv" if $opt_pc ne "";
   $pattern = "_k" . $opt_pc . "agent\.inv" if $opt_pc ne "";
   $pattern = "_" . $opt_pc . "_k" . $opt_pc . "cma\.inv" if $opt_pc eq "nt";
   @results = ();
   opendir(DIR,$opt_logpath) || die("cannot opendir $opt_logpath: $!\n"); # get list of files
   @results = grep {/$pattern/} readdir(DIR);
#DB::single=2;
   closedir(DIR);
   die "No _*.inv found\n" if $#results == -1;
   $logfn =  $results[0];
   if ($#results > 0) {         # more than one inv file - determine which one has most recent date
      my $last_modify = 0;
      $logfn =  $results[0];
      for my $r (@results) {
         my $testpath = $opt_logpath . $r;
         my $modify = (stat($testpath))[9];
         if ($last_modify == 0) {
            $logfn = $r;
            $last_modify = $modify;
            next;
         }
         next if $modify < $last_modify;
         $logfn = $r;
         $last_modify = $modify;
      }
   }
}

my %logbasex;
$full_logfn = $opt_logpath . $logfn;
if ($logfn =~ /.*\.inv$/) {
   open(INV, "< $full_logfn") || die("Could not open inv  $full_logfn\n");
   my @inv = <INV>;
   close(INV);
   my $l = 0;
   die "empty INV file $full_logfn\n" if $#inv == -1;
   foreach my $inline (@inv) {
      $inline =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments
      $pos = rindex($inline,'/');
      $inline = substr($inline,$pos+1);
      $inline =~ m/(.*)-\d\d\.log$/;
      $inline =~ m/(.*)-\d\.log$/ if !defined $1;
      die "invalid log form $inline from $full_logfn line $l\n" if !defined $1;
      $logbase = $1;
      $logfn = $1 . '-*.log';
      $logbasex{$logbase} = 1;
      last if $opt_allinv == 0;
   }
}


my $base_ct = scalar keys %logbasex;
if ($base_ct == 0) {
   $logbasex{$logfn} = 1;
}

#if (!defined $logbase) {
#  $logbasex{$logfn} = 1 if ! -e $logfn;
#   $logbasex{$logfn} = 1;
#}

sub open_kib;
sub close_kib;
sub read_kib;

my $ll = 0;
foreach my $log (keys %logbasex) {
   $ll += 1;
   $logbase = $log;
   do_rpt;
}

if ($opt_merge == 1) {
   my $mfn = "merge.csv";
   open MH, ">$mfn" or die "can't open $mfn: $!";
   foreach $f ( sort { $a cmp $b} keys %timelinexx) {
      my $ml_ref = $timelinexx{$f};
      $outl = sec2ltime($ml_ref->{time}+$local_diff) . ",";
      $outl .= $ml_ref->{hextime} . ",";
      $outl .= $ml_ref->{l} . ",";
      $outl .= $ml_ref->{advisory} . ",";
      $outl .= $ml_ref->{notes} . ",";
      $outl .= $ml_ref->{logbase} . ",";
      print MH "$outl\n";
   }
   close MH;
}

exit 0;


sub do_rpt {

   $cnt = -1;
   @oline = ();
   $hdri = -1;                               # some header lines for report
   @hdr = ();                                #
   $advisori = -1;
   @advisor = ();
   %timelinex = ();
   $timeline_start = 0;
   %envx = ();
   %rpcrunx = ();
   @dlogfiles = [];
   @seg = ();
   @seg_time = ();
   $segi = -1;
   $segp = -1;
   $segcur = "";
   $segline = "";
   $segmax = 0;
   %todo = ();

   $hdri++;$hdr[$hdri] = "TEMA Workload Advisory report v$gVersion";
   my $audit_start_time = gettime();       # formated current time for report
   $hdri++;$hdr[$hdri] = "Start: $audit_start_time";

   open_kib();

   $l = 0;

   my $locus;                  # (4D81D81A.0000-A1A:kpxrpcrq.cpp,749,"IRA_NCS_Sample")
   my $rest;                   # unprocesed data
   my $logtime;                # distributed time stamp in seconds - number of seconds since Jan 1, 1970
   my $logtimehex;             # distributed time stamp in hex
   my $logline;                # line number within $logtimehex
   my $logthread;              # thread information - prefixed with "T"
   my $logunit;                # where printed from - kpxrpcrq.cpp,749
   my $logentry;               # function printed from - IRA_NCS_Sample
   my $trcstime = 0;           # trace smallest time seen - distributed
   my $trcetime = 0;           # trace largest time seen  - distributed


   # running action command captures.
   # used during capture of data
   my %contx = ();                              # index from cont to same array using hextime.line
   my $contkey;

   # following are in the $runx value, which is actually an array
   my $runref;                                  # reference to array
   my $trace_ct = 0;               # count of trace lines
   my $trace_sz = 0;               # total size of trace lines


   my $state = 0;       # 0=look for offset, 1=look for zos initial record, 2=look for zos continuation, 3=distributed log
   my $timeline = "";          # time portion of timestamp
   my $offset = 0;             # track sysout print versus disk flavor of RKLVLOG
   my $outl;



   my %epoch = ();             # convert year/day of year to Unix epoch seconds
   my $yyddd;
   my $yy;
   my $ddd;
   my $days;
   my $oplogid;

   my $lagline;
   my $lagopline;
   my $lagtime;
   my $laglocus;

   if ($opt_z == 1) {$state = 1}

   for(;;)
   {
      read_kib();
      if (!defined $inline) {
         close_kib();
         last;
      }
      $l++;
      if ($l%10000 == 0) {
         print STDERR "Working on $l\n" if $opt_vv == 1;
      }
   # following two lines are used to debug errors. First you flood the
   # output with the working on log lines, while merging stdout and stderr
   # with  1>xxx 2>&1. From that you determine what the line number was
   # before the faulting processing. Next you turn that off and set the conditional
   # test for debugging and test away.
   # print STDERR "working on log $segcurr at $l\n";

      chomp($inline);
      if ($opt_z == 1) {
         if (length($inline) > 132) {
            $inline = substr($inline,0,132);
         }
         next if length($inline) <= 21;
      }
      if (($segmax == 0) or ($segp > 0)) {
         if ($skipzero == 0) {
            $trace_ct += 1;
            $trace_sz += length($inline);
         }
      }
      if ($state == 0) {                       # state = 0 distributed log - no filtering - following is pure z logic
         $oneline = $inline;
      }
      elsif ($state == 1) {                       # state 1 - detect print or disk version of sysout file
         $offset = (substr($inline,0,1) eq "1") || (substr($inline,0,1) eq " ");
         $state = 2;
         $lagopline = 0;
         $lagtime = 0;
         $laglocus = "";
         next;
      }
      elsif ($state == 2) {                    # state 2 = look for part one of target lines
         next if length($inline) < 36;
         next if substr($inline,21+$offset,1) ne '(';
         next if substr($inline,26+$offset,1) ne '-';
         next if substr($inline,35+$offset,1) ne ':';
         next if substr($inline,0+$offset,2) != '20';

         # convert the yyyy.ddd hh:mm:ss:hh stamp into the epoch seconds form.
         # The goal is to allow a common logic for z/OS and distributed logs.

         # for year/month/day calculation is this:
         #   if ($mo > 2) { $mo++ } else {$mo +=13;$yy--;}
         #   $day=($yy*365)+int($yy/4)-int($yy/100)+int($yy/400)+int($mo*306001/10000)+$dd;
         #   $days_since_epoch=$day-719591; # (which is Jan 1 1970)
         #
         # In this case we need the epoch days for begining of Jan 1 of current year and then add day of year
         # Use an associative array part so the day calculation only happens once a day.
         # The result is normalized to UTC 0 time [like GMT] but is fine for duration calculations.

         $yyddd = substr($inline,0+$offset,8);
         $timeline = substr($inline,9+$offset,11);
         if (!defined $epoch{$yyddd}){
            $yy = substr($yyddd,0,4);
            $ddd = substr($yyddd,5,3);
            $yy--;
            $days=($yy*365)+int($yy/4)-int($yy/100)+int($yy/400)+int(14*306001/10000)+$ddd;
            $epoch{$yyddd} = $days-719591;
         }
         $lagtime = $epoch{$yyddd}*86400 + substr($timeline,0,2)*3600 + substr($timeline,3,2)*60 + substr($timeline,6,2);
         $lagline = substr($inline,21+$offset);
         $lagline =~ /^\((.*?)\)/;
         $laglocus = "(" . $1 . ")";
         $state = 3;
         next;
      }

      # continuation is without a locus
      elsif ($state == 3) {                    # state 3 = potentially collect second part of line
         # case 1 - look for the + sign which means a second line of trace output
         #   emit data and resume looking for more
         if (substr($inline,21+$offset,1) eq "+") {
            next if $lagline eq "";
            $oneline = $lagline;
            $logtime = $lagtime;
            $lagline = $inline;
            $lagtime = $lagtime;
            $laglocus = "";
            $state = 3;
            # fall through and process $oneline
         }

         # case 3 - line too short for a locus
         #          Append data to lagline and move on
         elsif (length($inline) < 35 + $offset) {
            $lagline .= " " . substr($inline,21+$offset);
            $state = 3;
            next;
         }

         # case 4 - line has an apparent locus, emit laggine line
         #          and continue looking for data to append to this new line
         elsif ((substr($inline,21+$offset,1) eq '(') &&
                (substr($inline,26+$offset,1) eq '-') &&
                (substr($inline,35+$offset,1) eq ':') &&
                (substr($inline,0+$offset,2) eq '20')) {
            if ($lagopline == 1) {
               if ($opt_zop ne "") {
                  print ZOP "$lagline\n";
               }
               $lagopline = 0;
            }
            $oneline = $lagline;
            $logtime = $lagtime;
            $yyddd = substr($inline,0+$offset,8);
            $timeline = substr($inline,9+$offset,11);
            if (!defined $epoch{$yyddd}){
               $yy = substr($yyddd,0,4);
               $ddd = substr($yyddd,5,3);
               $yy--;
               $days=($yy*365)+int($yy/4)-int($yy/100)+int($yy/400)+int(14*306001/10000)+$ddd;
              $epoch{$yyddd} = $days-719591;

            }
            $lagtime = $epoch{$yyddd}*86400 + substr($timeline,0,2)*3600 + substr($timeline,3,2)*60 + substr($timeline,6,2);
            $lagline = substr($inline,21+$offset);
            $lagline =~ /^\((.*?)\)/;
            $laglocus = "(" . $1 . ")";
            $state = 3;
            # fall through and process $oneline
         }

         # case 5 - Identify and ignore lines which appear to be z/OS operations log entries
         else {
            $oplogid = substr($inline,21+$offset,7);
            $oplogid =~ s/\s+$//;
            if ((substr($oplogid,0,3) eq "OM2") or
                (substr($oplogid,0,1) eq "K") or
                (substr($oplogid,0,1) eq "O")) {
               if ($lagopline == 1) {
                  if ($opt_zop ne "") {
                     print ZOP "$lagline\n";
                  }
               }
                $lagopline = 1;
                $lagline = substr($inline,$offset);
            } else {
                $lagline .= substr($inline,21+$offset);
            }
            $state = 3;
            next;
         }
      }
      else {                   # should never happen
         print STDERR $oneline . "\n";
         die "Unknown state [$state] working on log $logfn at $l\n";
         next;
      }

      if ($start_date eq "") {
         if (substr($oneline,0,1) eq "+") {
            if (index($oneline,"Start Date:") != -1) {
               $oneline =~ /Start Date: (\d{4}\/\d{2}\/\d{2})/;
               $start_date = $1 if defined $1;
            }
         }
      }
      if ($start_time eq "") {
         if (substr($oneline,0,1) eq "+") {
            if (index($oneline,"Start Time:") != -1) {
               $oneline =~ /Start Time: (\d{2}:\d{2}:\d{2})/;
               $start_time = $1 if defined $1;
            }
         }
       }

       #(5AA2E31C.0000-7E4:kdcc1sr.c,642,"rpc__sar") Remote call failure: 1C010001
       #+5AA2E31C.0000   activity: 11f0f9725f90.42.02.ac.13.80.05.06.94   started: 5AA2E196
       #+5AA2E31C.0000  interface: 6f21c4ad7f33.02.c6.d2.23.0c.00.00.00   version: 131
       #+5AA2E31C.0000     object: 5e3d67a8d345.02.81.00.e7.48.00.00.00     opnum: 2
       #+5AA2E31C.0000  srvr-boot: 5A791892        length: 1058         a/i-hints: FFA5/000D
       #+5AA2E31C.0000   sent-req: true         sent-last: true              idem: false
       #+5AA2E31C.0000      maybe: false            large: true          callback: false
       #+5AA2E31C.0000  snd-frags: false        rcv-frags: false            fault: false
       #+5AA2E31C.0000     reject: false          pkts-in: 8             pkts-bad: 0
       #+5AA2E31C.0000    pkts-cb: 0            pkts-wact: 0            pkts-oseq: 8
       #+5AA2E31C.0000    pkts-ok: 0             duration: 390              state: 1
       #+5AA2E31C.0000   interval: 30             retries: 0                pings: 12
       #+5AA2E31C.0000   no-calls: 0              working: 0                facks: 0
       #+5AA2E31C.0000      waits: 14            timeouts: 13            sequence: 506
       #+5AA2E31C.0000     b-size: 32              b-fail: 0               b-hist: 0
       #+5AA2E31C.0000   nextfrag: 2              fragnum: 0
       #+5AA2E31C.0000     w-secs: 390             f-secs: 360             l-secs: 900
       #+5AA2E31C.0000     e-secs: 0                  mtu: 944         KDE1_stc_t: 1DE0000F
       #+5AA2E31C.0000   bld-date: Mar 27 2013   bld-time: 13:15:55      revision: D140831.1:1.1.1.13
       #+5AA2E31C.0000        bsn: 4323373            bsq: 5               driver: tms_ctbs623fp3:d3086a
       #+5AA2E31C.0000      short: 10             contact: 180              reply: 300
       #+5AA2E31C.0000    req-int: 30            frag-int: 30            ping-int: 30
       #+5AA2E31C.0000      limit: 900         work-allow: 60
       #+5AA2E31C.0000  loc-endpt: ip.spipe:#*:7759
       #+5AA2E31C.0000  rmt-endpt: ip.spipe:#146.89.140.75:3660
       if (substr($oneline,0,1) eq "+") {
          if (defined $logtime) {
             my $rpckey = $logtime . "|" . $logline;
             if (defined $rpckey) {
                my $rpc_ref = $rpcrunx{$rpckey};
                if (defined $rpc_ref) {
                  my $pline = substr($oneline,15);  #   srvr-boot: 5A791892        length: 1058         a/i-hints: FFA5/000D
                  $pline =~ s/^\s+|\s+$//;     # strip leading/trailing white space
                  $pline =~ s/: /:/g;
                  @segs = split("[ ]{2,99}",$pline);
                  my $iattr = "";
                  my $ivalue = "";
                  foreach my $f (@segs) {
                     $f =~  s/^\s+|\s+$//;     # strip leading/trailing white space
                     my @parts = split(":(?!#)",$f);
                     $iattr = $parts[0];
                     $ivalue = $parts[1];
                     $iattr =~ s/^\s+|\s+$//;     # strip leading/trailing white space
                     $ivalue =~ s/^\s+|\s+$//;     # strip leading/trailing white space
                     $rpc_ref->{$iattr} = $ivalue;
                  }
                  if ($iattr eq "rmt-endpt") {
                     my $lstarted = sec2ltime(hex($rpc_ref->{started})+$local_diff);
                     my $inotes = "started[$lstarted] ";
                     $inotes .= 'loc-endpt' . "[$rpc_ref->{'loc-endpt'}] ";
                     $inotes .= 'rmt-endpt' . "[$rpc_ref->{'rmt-endpt'}] " if defined $rpc_ref->{'rmt-endpt'};
                     $inotes .= "mtu[$rpc_ref->{mtu}] " if defined $rpc_ref->{'mtu'};
                     $inotes .= "timeouts[$rpc_ref->{timeouts}] " if defined $rpc_ref->{'timeouts'};
                     my $msg_ref = "";
                     if (defined $rpc_ref->{'KDE1_stc_t'}) {
                        my @msg_ref = $kdemsgx{$rpc_ref->{KDE1_stc_t}};
                        my $msg_txt = $msg_ref[0][1] . " \"" . $msg_ref[0][0] . "\"";
                        $inotes .= "KDE1_stc_t[$rpc_ref->{KDE1_stc_t} $msg_txt]";
                     }
                     set_timeline($logtime,$l,$logtimehex,2,"RPC-Fail",$inotes);
                     delete $rpcrunx{$rpckey};
                  }
               }
             }
          }
       }




      if (substr($oneline,0,1) eq "+")  {
         $contkey = substr($oneline,1,13);
         $runref = $contx{$contkey};
         if (defined $runref) {
            if ($runref->{'state'} == 3) {
               my $cmd_frag = substr($oneline,30,36);
               $cmd_frag =~ s/\ //g;
               $cmd_frag =~ s/(([0-9a-f][0-9a-f])+)/pack('H*', $1)/ie;
               $runref->{'cmd'} .= $cmd_frag;
            }
         }
      }
      if (substr($oneline,0,1) ne "(") {next;}
      $oneline =~ /^(\S+).*$/;          # extract locus part of line
      $locus = $1;
      if ($opt_z == 0) {                # distributed has five pieces
         $locus =~ /\((.*)\.(.*)-(.*):(.*)\,\"(.*)\"\)/;
         next if index($1,"(") != -1;   # ignore weird case with embedded (
         $logtime = hex($1);            # decimal epoch
         $logtimehex = $1;              # hex epoch
         $logline = $2;                 # line number following hex epoch, meaningful with there are + extended lines
         $logthread = "T" . $3;         # Thread key
         $logunit = $4;                 # source unit and line number
         $logentry = $5;                # function name
      }
      else {                            # z/OS has three pieces
         $locus =~ /\((.*)-(.*):(.*),\"(.*)\"\)/;
         $logline = 0;      ##???
         $logthread = "T" . $2;
         $logunit = $3;
         $logentry = $4;
      }
      # following calculates difference between diagnostic log
      # time and the local time as recorded in RAS1 header lines
      if ($local_diff == -1) {
         if ($start_time ne "") {
            if ($start_date ne "") {
               my $iyear = substr($start_date,0,4) - 1900;
               my $imonth = substr($start_date,5,2) - 1;
               my $iday = substr($start_date,8,2);
               my $ihour = substr($start_time,0,2);
               my $imin = substr($start_time,3,2);
               my $isec = substr($start_time,6,2);
               my $ltime = timelocal($isec,$imin,$ihour,$iday,$imonth,$iyear);
               $local_diff = $ltime - $logtime;
            }
         }
      }
      if ($skipzero == 0) {
         if (($segmax <= 1) or ($segp > 0)) {
            if ($trcstime == 0) {
               $trcstime = $logtime;
               $trcetime = $logtime;
            }
            if ($logtime < $trcstime) {
               $trcstime = $logtime;
            }
            if ($logtime > $trcetime) {
               $trcetime = $logtime;
            }
         }
      }
      set_timeline($logtime,$l,$logtimehex,-1,"Log","Start") if $timeline_start == 0;
      $timeline_start = 1;

      #(5A9E41FE.0088-7BC:kraarreg.cpp,1075,"ConnectToProxy") Successfully connected to CMS REMOTE_usrdrtm041ccpr2 using ip.spipe:#146.89.140.75[3660]
      #(5AA2E3F5.000A-9F0:kraarreg.cpp,2907,"PrimaryTEMSperiodicLookupThread") Primary TEMS <IP.SPIPE:146.89.140.75> Current connected TEMS <146.89.140.76>
      #(5AA2E3F4.0001-13E0:kraarreg.cpp,1781,"LookupAndRegisterWithProxy") Unable to connect to broker at ip.spipe:usrdrtm041ccpr2.ssm.sdc.gts.ibm.com: status=0, "success", ncs/KDC1_STC_OK

      if (substr($logunit,0,12) eq "kraarreg.cpp") {
         if ($logentry eq "ConnectToProxy") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; # Successfully connected to CMS REMOTE_usrdrtm041ccpr2 using ip.spipe:#146.89.140.75[3660]
            if (substr($rest,1,22) eq "Successfully connected") {
               $rest =~ /to CMS (\S+) using (\S+)/;
               my $items = $1;
               my $iconn = $2;
               set_timeline($logtime,$l,$logtimehex,1,"Communications ,substr($rest,1));
               $iconn =~ /\[(\d+)\]/;
               $iport = $1;
               if (defined $iport) {
                  my $m = $l . "a";
                  set_timeline($logtime,$m,$logtimehex,4,"Communications",$iport);  # record TEMS port
               }
               next;
            }
         }
         if ($logentry eq "PrimaryTEMSperiodicLookupThread") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2;
            set_timeline($logtime,$l,$logtimehex,0,"Fallback",substr($rest,1));
            next;
         }
         if ($logentry eq "LookupAndRegisterWithProxy") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2;
            set_timeline($logtime,$l,$logtimehex,0,"RegisterWithProxy",substr($rest,1));
            next;
         }
      }
      #(5A9E41FD.0053-698:kbbssge.c,52,"BSS1_GetEnv") CT_CMSLIST="IP.SPIPE:146.89.140.75;IP.PIPE:146.89.140.75;IP.SPIPE:146.89.140.76;IP.PIPE:146.89.140.76"
      if (substr($logunit,0,9) eq "kbbssge.c") {
         if ($logentry eq "BSS1_GetEnv") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; # CT_CMSLIST="IP.SPIPE:146.89.140.75;IP.PIPE:146.89.140.75;IP.SPIPE:146.89.140.76;IP.PIPE:146.89.140.76"
            $rest =~ / (\S+?)=(.*)/;
            my $ienv = $1;
            if (!defined $envx{$ienv}) {
               if (($opt_allenv == 1) or (defined $commenvx{$ienv})) {
                  $envx{$ienv} = 1;
                  set_timeline($logtime,$l,$logtimehex,0,"EnvironmentVariables",substr($rest,1));
               }
            }
            next;
         }
      }
      #(5AA2E3F5.0008-13E0:kraaulog.cpp,755,"IRA_OutputLogMsg") Connecting to CMS REMOTE_usrdrtm051ccpr2
      if (substr($logunit,0,12) eq "kraaulog.cpp") {
         if ($logentry eq "IRA_OutputLogMsg") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; #  Connecting to CMS REMOTE_usrdrtm051ccpr2
            set_timeline($logtime,$l,$logtimehex,0,"OPLOG",substr($rest,1));
            next;
         }
      }
      #(5AA2E3F5.0006-13E0:kdcc1wh.c,114,"conv__who_are_you") status=1c010008, "activity not in call", ncs/KDC1_STC_NOT_IN_CALL
      if (substr($logunit,0,9) eq "kdcc1wh.c") {
         if ($logentry eq "conv__who_are_you") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; #  status=1c010008, "activity not in call", ncs/KDC1_STC_NOT_IN_CALL
            set_timeline($logtime,$l,$logtimehex,0,"ANC",substr($rest,1));
            next;
         }
      }
      #(5AA2E3F1.0000-13E0:kdcc1sr.c,642,"rpc__sar") Endpoint unresponsive: "ip.spipe:#146.89.140.75:3660", 1C010001:1DE0000F, 210, 5(2), FFFF/1, D140831.1:1.1.1.13, tms_ctbs623fp3:d3086a
      #(5AA2E31C.0000-7E4:kdcc1sr.c,642,"rpc__sar") Remote call failure: 1C010001
      #(5AB93569.0000-14C8:kdcc1sr.c,670,"rpc__sar") Connection lost: "ip.spipe:#146.89.140.75:65100", 1C010001:1DE0004D, 30, 100(5), FFFF/40, D140831.1:1.1.1.13, tms_ctbs630fp7:d6305a

      if (substr($logunit,0,9) eq "kdcc1sr.c") {
         if ($logentry eq "rpc__sar") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; #  Endpoint unresponsive: "ip.spipe:#146.89.140.75:3660", 1C010001:1DE0000F, 210, 5(2), FFFF/1, D140831.1:1.1.1.13, tms_ctbs623fp3:d3086a
            if (substr($rest,1,19) eq "Remote call failure") { # need more work here
               my %rpcref = ();
               my $rpckey = $logtime . "|" . $logline;
               $rpcrunx{$rpckey} = \%rpcref;
            } else {
               set_timeline($logtime,$l,$logtimehex,2,"RPC",substr($rest,1));
            }
            next;
         }
      }
      #(5AA2E31F.0000-7E4:kraarpcm.cpp,1024,"evaluateStatus") RPC call Sample for <2817540636,3532653436> failed, status = 1c010001
      if (substr($logunit,0,12) eq "kraarpcm.cpp") {
         if ($logentry eq "evaluateStatus") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; # RPC call Sample for <2817540636,3532653436> failed, status = 1c010001
            set_timeline($logtime,$l,$logtimehex,2,"Communications",substr($rest,1));
            next;
         }
      }
      #(5AA2E3F4.0000-13E0:kdcl0cl.c,142,"KDCL0_ClientLookup") status=1c020006, "location server unavailable", ncs/KDC1_STC_SERVER_UNAVAILABLE
      if (substr($logunit,0,9) eq "kdcl0cl.c") {
         if ($logentry eq "KDCL0_ClientLookup") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; # status=1c020006, "location server unavailable", ncs/KDC1_STC_SERVER_UNAVAILABLE
            set_timeline($logtime,$l,$logtimehex,2,"Communications",substr($rest,1));
            next;
         }
      }

   }
   set_timeline($logtime,$l,$logtimehex,3,"Log","End",);

   # Communication activity timeline
      $rptkey = "AGENTREPORT010";$advrptx{$rptkey} = 1;         # record report key
      my $nstate = 1;                                           # waiting for TEMS connection
                                                               # 2 waiting for errors
      my $tems_last = "";
      my $tems_ip = "";
      my $tems_port = "";
      my $tems_time = 0;
      my $temsfail = 0;
      my $temsfail_ct = 0;
      my $temsfail_sec = 0;
      my $commfail_ct = 0;
      my $commfail_sec = 0;
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: Timeline of TEMS connectivity\n";
      $cnt++;$oline[$cnt]="LocalTime,Hextime,Line,Advisory/Report,Notes,\n";
      foreach $f ( sort { $a cmp $b} keys %timelinex) {
         my $tl_ref = $timelinex{$f};
         if ($nstate == 1) {
            if ($tl_ref->{badcom} == 1) {   # connected to CMS
               $tl_ref->{notes} =~ /Successfully connected to CMS (\S+) using (\S+)/;
               $tems_last = $1;
               $tems_ip = $2;
               $tems_time = $tl_ref->{time};
               $outl = sec2ltime($tl_ref->{time}+$local_diff) . ",";
               $outl .= $tems_last . ",";
               $outl .= $tems_ip . ",";
               if ($commfail_ct == 0) {
                  $outl .= "Connecting to TEMS,";
               } else {   # comm errors
                  my $tsecs = $tl_ref->{time} - $commfail_sec;
                  my $psecs = $tsecs%86400;
                  my $pdays = int($tsecs/86400);
                  $pdiff = $pdays . "/" . strftime("\%H:\%M:\%S",gmtime($psecs));
                  $outl .= "Connecting to TEMS after $commfail_ct errors recorded over $pdiff,";
               }
               $commfail_ct = 0;
               $commfail_sec = 0;
               $cnt++;$oline[$cnt]="$outl\n";
               $nstate = 2;
            } elsif ($tl_ref->{badcom} == 2) {
               my $temsfail = 0;
               if ($tems_port ne "") {
                  $temsfail = 1 if index($tl_ref->{notes},$tems_port) != -1;
               }
               if ($temsfail == 0) {
                  $tl_ref->{notes} =~ /\#.*?\:(\d+)\"/;
                  $iport = $1;
                  $porterrx{$iport} += 1 if defined $iport;
                  $commfail_ct += 1;
                  $commfail_sec = $tl_ref->{time} if $commfail_sec == 0;
               } else {
                  $temsfail_ct += 1;
                  $temsfail_sec = $tl_ref->{time} if $temsfail_sec == 0;
               }
            } elsif ($tl_ref->{badcom} == 3) { #end of log
               $outl = sec2ltime($tl_ref->{time}+$local_diff) . ",";
               $tems_time = $tl_ref->{time};
               my $tsecs = $tl_ref->{time} - $commfail_sec;
               my $psecs = $tsecs%86400;
               my $pdays = int($tsecs/86400);
               $pdiff = $pdays . "/" . strftime("\%H:\%M:\%S",gmtime($psecs));
               $outl .= "Ended with no connection to TEMS after $commfail_ct errors recorded over $pdiff,";
               $cnt++;$oline[$cnt]="$outl\n";
            } elsif ($tl_ref->{badcom} == 4) { #TEMS port defined
               $tems_port = $tl_ref->{notes};
            } elsif ($tl_ref->{badcom} == -1) { # start of log
               $outl = sec2ltime($tl_ref->{time}+$local_diff) . ",Log,Start";
               $cnt++;$oline[$cnt]="$outl\n";
            }

         } elsif ($nstate == 2) {
            if ($tl_ref->{badcom} == 4) { #TEMS port defined
               $tems_port = $tl_ref->{notes};
            } elsif ($tl_ref->{badcom} == 1) {   # connected to CMS - again!
               $outl = sec2ltime($tl_ref->{time}+$local_diff) . ",";
               $outl .= $tems_last . ",";
               $outl .= $tems_ip . ",";
               $tdiff = $tl_ref->{time} - $tems_time;
               my $psecs = $tdiff%86400;
               my $pdays = int($tdiff/86400);
               $pdiff = $pdays . "/" . strftime("\%H:\%M:\%S",gmtime($psecs));
               $outl .= "reconnect to TEMS $tems_last without obvious comm failure after $pdiff,";
               $cnt++;$oline[$cnt]="$outl\n";
               $tl_ref->{notes} =~ /Successfully connected to CMS (\S+) using (\S+)/;
               $tems_last = $1;
               $tems_ip = $2;
               $tems_time = $tl_ref->{time};
               $outl = sec2ltime($tl_ref->{time}+$local_diff) . ",";
               $outl .= $tems_last . ",";
               $outl .= $tems_ip . ",";
               $outl .= "Connecting to TEMS,";
               $cnt++;$oline[$cnt]="$outl\n";
            } elsif ($tl_ref->{badcom} == 2) { # communications failure
               if ($tems_port ne "") {
                  if (index($tl_ref->{notes},$tems_port) != -1) {  # communications failure on TEMS port
                     $tdiff = $tl_ref->{time} - $tems_time;
                     my $psecs = $tdiff%86400;
                     my $pdays = int($tdiff/86400);
                     $pdiff = $pdays . "/" . strftime("\%H:\%M:\%S",gmtime($psecs));
                     $outl = sec2ltime($tl_ref->{time}+$local_diff) . ",";
                     $outl .= "Communications failure after $pdiff,";
                     $cnt++;$oline[$cnt]="$outl\n";
                     $temsfail_ct = 1;
                     $temsfail_sec = $tl_ref->{time};
                     $tems_port = "";
                     $nstate = 1;
                  } else {
                     $tl_ref->{notes} =~ /\#.*?\:(\d+)\"/;
                     $iport = $1;
                     $porterrx{$iport} += 1 if defined $iport;
                     $commfail_ct = 1;
                     $commfail_sec = $tl_ref->{time};
                  }
               }
            } elsif ($tl_ref->{badcom} == 3) { # end of log
               $outl = sec2ltime($tl_ref->{time}+$local_diff) . ",";
               $outl .= $tems_last . ",";
               $outl .= $tems_ip . ",";
               $tdiff = $tl_ref->{time} - $tems_time;
               my $psecs = $tdiff%86400;
               my $pdays = int($tdiff/86400);
               $pdiff = $pdays . "/" . strftime("\%H:\%M:\%S",gmtime($psecs));
               $outl .= "Log ended with connection to TEMS $tems_last after $pdiff,";
               my $porterr_ct = scalar keys %porterrx;
               if ($porterr_ct > 0) {
                  $pporterr = "non-TEMS port errors:";
                  foreach my $p (keys %porterrx) {
                     $pporterr .= $p . "[" . $porterrx{$p} . "] ";
                  }
                 chop $pporterr;
                 $pporterr .= ",";
               }
               $outl .= $pporterr if defined $pporterr;
               $cnt++;$oline[$cnt]="$outl\n";
            } elsif ($tl_ref->{badcom} == -1) { # Start of log
               $outl = sec2ltime($tl_ref->{time}+$local_diff) . ",Log,Start";
               $cnt++;$oline[$cnt]="$outl\n";
            }
         }
      }

      $rptkey = "AGENTREPORT011";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: Timeline of Communication events\n";
      $cnt++;$oline[$cnt]="LocalTime,Hextime,Line,Advisory/Report,Notes,\n";
      foreach $f ( sort { $a cmp $b} keys %timelinex) {
         my $tl_ref = $timelinex{$f};
         if ($tl_ref->{advisory} eq "EnvironmentVariables") {
            if (index($tl_ref->{notes},"KDE_TRANSPORT") != -1) {
               if (index($tl_ref->{notes},"idle:") != -1) {
                  $advisori++;$advisor[$advisori] = "Advisory: KDC_FAMILIES includes idle: setting - $tl_ref->{notes}";
               }
            }
         }
         $outl = sec2ltime($tl_ref->{time}+$local_diff) . ",";
         $outl .= $tl_ref->{hextime} . ",";
         $outl .= $tl_ref->{l} . ",";
         $outl .= $tl_ref->{advisory} . ",";
         $outl .= $tl_ref->{notes} . ",";
         $cnt++;$oline[$cnt]="$outl\n";

         my $mkey = sec2ltime($tl_ref->{time}+$local_diff) . "|" . $tl_ref->{l};
         my $ml_ref = $timelinexx{$mkey};
         if (!defined $ml_ref) {
            my %mlref = (   time => $tl_ref->{time},
                            hextime => $tl_ref->{hextime},
                            l => $tl_ref->{l},
                            advisory => $tl_ref->{advisory},
                            notes => $tl_ref->{notes},
                            logbase => $logbase,
                        );

            $ml_ref = \%mlref;
            $timelinexx{$mkey} = \%mlref;
         }
   }

   if ($opt_pc ne "") {
      $opt_o = "logcomm_" . $opt_pc . ".csv" if $opt_o eq "logcomm.csv";
   }
   my $ofn = $opt_o;
   $ofn = $logbase . "_" . $opt_o if $opt_allinv == 1;

   open OH, ">$ofn" or die "can't open $ofn: $!";

   if ($opt_nohdr == 0) {
      for (my $i=0;$i<=$hdri;$i++) {
         $outl = $hdr[$i] . "\n";
         print OH $outl;
      }
      print OH "\n";
   }
   if ($advisori == -1) {
      print OH "No Expert Advisory messages\n";
   } else {
      for (my $i=0;$i<=$advisori;$i++){
         print OH "$advisor[$i]\n";
      }
   }
   print OH "\n";

   for (my $i=0;$i<=$cnt;$i++) {
      print OH $oline[$i];
   }

   close OH;
   close(ZOP) if $opt_zop ne "";
}


sub open_kib {
   # get list of files
   if (-e $logfn) {
         $segi += 1;
         $seg[$segi] = $logfn;
         $segmax = 0;
   } else {
      $logpat = $logbase . '-.*\.log' if defined $logbase;
      opendir(DIR,$opt_logpath) || die("cannot opendir $opt_logpath: $!\n");
      @dlogfiles = grep {/$logpat/} readdir(DIR);
      closedir(DIR);
      die "no log files found with given specifcation\n" if $#dlogfiles == -1;

      my $dlog;          # fully qualified name of diagnostic log
      my $oneline;       # local variable
      my $tlimit = 100;  # search this many times for a timestamp at begining of a log
      my $t;
      my $tgot;          # track if timestamp found
      my $itime;

      foreach $f (@dlogfiles) {
         $f =~ /^.*-(\d+)\.log/;
         $segmax = $1 if $segmax == 0;
         $segmax = $1 if $segmax < $1;
         $dlog = $opt_logpath . $f;
         open($dh, "< $dlog") || die("Could not open log $dlog\n");
         for ($t=0;$t<$tlimit;$t++) {
            $oneline = <$dh>;                      # read one line
            next if $oneline !~ /^.(.*?)\./;       # see if distributed timestamp in position 1 ending with a period
            $oneline =~ /^.(.*?)\./;               # extract value
            $itime = $1;
            next if length($itime) != 8;           # should be 8 characters
            next if $itime !~ /^[0-9A-F]*/;            # should be upper cased hex digits
            $tgot = 1;                             # flag gotten and quit
            last;
         }
         close($dh);
         if ($tgot == 0) {
            print STDERR "the log $dlog ignored, did not have a timestamp in the first $tlimit lines.\n";
            next;
         }
         $todo{$dlog} = hex($itime);               # Add to array of logs
      }
      $segmax -= 1;

      foreach $f ( sort { $todo{$a} <=> $todo{$b} } keys %todo ) {
         $segi += 1;
         $seg[$segi] = $f;
         $seg_time[$segi] = $todo{$f};
      }
   }
}
sub close_kib {
   close(KIB);
   $segp = -1;
}

sub read_kib {
   if ($segp == -1) {
      $segp = 0;
      if ($segmax > 0) {
         my $seg_diff_time = $seg_time[1] - $seg_time[0];
         if ($seg_diff_time > 3600) {
            $skipzero = 1;
         }
      }
      $segcurr = $seg[$segp];
      open(KIB, "<$segcurr") || die("Could not open log segment $segp $segcurr\n");
      print STDERR "working on $segp $segcurr\n" if $opt_v == 1;
      $hdri++;$hdr[$hdri] = '"' . "working on $segp $segcurr" . '"';
      $segline = 0;
   }
   $segline ++;
   $inline = <KIB>;
   return if defined $inline;
   close(KIB);
   $segp += 1;
   $skipzero = 0;
   return if $segp > $segi;
   $segcurr = $seg[$segp];
   open(KIB, "<$segcurr") || die("Could not open log segment $segp $segcurr\n");
   print STDERR "working on $segp $segcurr\n" if $opt_v == 1;
   $hdri++;$hdr[$hdri] = '"' . "working on $segp $segcurr" . '"';
   $segline = 1;
   $inline = <KIB>;
}

sub gettime
{
   my $sec;
   my $min;
   my $hour;
   my $mday;
   my $mon;
   my $year;
   my $wday;
   my $yday;
   my $isdst;
   ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
   return sprintf "%4d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec;
}

sub sec2ltime
{
   my ($itime) = @_;

   my $sec;
   my $min;
   my $hour;
   my $mday;
   my $mon;
   my $year;
   my $wday;
   my $yday;
   my $isdst;
   ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($itime);
   return sprintf "%4d%02d%02d%02d%02d%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec;
}

sub set_timeline {
   my ($ilogtime,$il,$ilogtimehex,$ibadcom,$iadvisory,$inotes) = @_;
   $tlkey = $ilogtime . "|" . $il;
   $tl_ref = $timelinex{$tlkey};
   if (!defined $tl_ref) {
      my %tlref = (
                     time => $ilogtime,
                     l => $il,
                     hextime => $ilogtimehex,
                     advisory => $iadvisory,
                     notes => $inotes,
                     badcom => $ibadcom,
                  );
      $timelinex{$tlkey} = \%tlref;
   }
}



#------------------------------------------------------------------------------
sub GiveHelp
{
  $0 =~ s|(.*)/([^/]*)|$2|;
  print <<"EndOFHelp";

  $0 v$gVersion

  This script raeds a TEMS diagnostic log and writes a report of certain
  log records which record the result rows.

  Default values:
    none

  Run as follows:
    $0  <options> log_file

  Options
    -h              display help information
    -z              z/OS RKLVLOG log
    -b              Show HEARTBEATs in Managed System section
    -v              Produce limited progress messages in STDERR
    -inplace        [default and not used - see work parameter]
    -logpath        Directory path to TEMS logs - default current directory
    -work           Copy files to work directory before analyzing.
    -workpath       Directory path to work directory, default is the system
                    Environment variable Windows - TEMP, Linux/Unix tmp

  Examples:
    $0  logfile > results.csv

EndOFHelp
exit;
}
#------------------------------------------------------------------------------
# 0.50000 - new script based on agentaud.pl version 0.87000
