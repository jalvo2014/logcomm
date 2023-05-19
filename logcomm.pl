#!/usr/local/bin/perl -w
#------------------------------------------------------------------------------
# Licensed Materials - Property of IBM (C) Copyright IBM Corp. 2010, 2010
# All Rights Reserved US Government Users Restricted Rights - Use, duplication
# or disclosure restricted by GSA ADP Schedule Contract with IBM Corp
#------------------------------------------------------------------------------

#  perl logcomm.pl diagnostic_log
#
#  Create a report on agent Communications from diagnostic log(s)
#
#  john alvord, IBM Corporation, 19 August 2019
#  jalvord@us.ibm.com
#
# tested on Windows Strawberry Perl 5.26.1
#
# $DB::single=2;   # remember debug breakpoint

$gVersion = 0.66000;
$gWin = (-e "C:/") ? 1 : 0;       # determine Windows versus Linux/Unix for detail settings

## Todos

## !!Check tasklist.info and see processes under more than one process ids
## UID        PID  PPID   LWP  C NLWP STIME TTY          TIME CMD
## root      7611     1  7611  0   61 Jun13 ?        00:00:36 /opt/IBM/ITM/lx8266/lz/bin/klzagent
## root     12164     1 12164  0   57 09:39 ?        00:00:00 /opt/IBM/ITM/lx8266/lz/bin/klzagent

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

## (5AA2E3F4.0002-13E0:kdepnpc.c,138,"KDEP_NewPCB") 146.89.140.75: D2D0037C, KDEP_pcb_t @ 3761330 created
## (5AA2E3F5.0000-13E0:kdepdpc.c,62,"KDEP_DeletePCB") D2D0037C: KDEP_pcb_t deleted
## (5AA2E3F5.0004-13E0:kdepnpc.c,138,"KDEP_NewPCB") 146.89.140.76: D2F00373, KDEP_pcb_t @ 37618E0 created
## (5AA2E3F5.0005-1A34:kdebpli.c,211,"KDEBP_Listen") pipe 2 assigned: PLE=1F4F9F0, count=1, hMon=D2B00381

## (5AA31B32.0001-9F0:kdepnpc.c,138,"KDEP_NewPCB") 146.89.140.75: D470034C, KDEP_pcb_t @ 375FBA0 created
## (5AA31B33.0000-9F0:kdepdpc.c,62,"KDEP_DeletePCB") D470034C: KDEP_pcb_t deleted

##  (5BCDDA1E.0019-5A0:kbbssge.c,72,"BSS1_GetEnv") CTIRA_HOSTNAME="cex_mxoccans02"
##  (5BCDDA1E.001A-5A0:kbbssge.c,72,"BSS1_GetEnv") CTIRA_NODETYPE="NT"
##  (5BCDDA1E.001B-5A0:kraafmgr.cpp,2100,"DeriveFullHostname") Full hostname set to "cex_mxoccans02:NT"
##  (5BCDDA1E.001C-5A0:kbbssge.c,72,"BSS1_GetEnv") CTIRA_SYSTEM_NAME="cex_mxoccans02"



# CPAN packages used
use Data::Dumper;               # debug
#use warnings::unused; # debug used to check for unused variables
use Time::Local;
use POSIX qw{strftime};

my $start_date = "";
my $start_time = "";
my $local_diff = -1;
my $system_name = "";

my $this_ihostname = "";
my $this_installer = "";
my $this_gskit64 = "";
my $this_gskit32 = "";

my %statex;
my $statei = 0;

my $isdaproduct;
my $isdatems;
my $isdavrmf;
my $isdafail = 0;

my %owngroupx;

my $phdri = -1;
my @phdr = [],

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
my $clog;
my $logfn;
my $logbase;
my $loginstance;
my $opt_v;
my $opt_vv;
my $opt_cmdall;                                  # show all commands

my %cmslx;
my %kdcx;

my %pcinstx = (
                 "lo" => 1,
              );

sub gettime;                             # get time
sub sec2ltime;
sub do_rpt;
sub do_instances;
sub do_single;

sub open_kib;
sub close_kib;
sub read_kib;


# allow user to set impact
my %advcx = (
              "COMMAUDIT1001W" => "90",
              "COMMAUDIT1002W" => "90",
              "COMMAUDIT1003W" => "90",
              "COMMAUDIT1004W" => "90",
              "COMMAUDIT1005W" => "90",
              "COMMAUDIT1006W" => "90",
              "COMMAUDIT1007E" => "100",
              "COMMAUDIT1008E" => "100",
              "COMMAUDIT1009E" => "100",
              "COMMAUDIT1010W" => "90",
              "COMMAUDIT1011W" => "95",
              "COMMAUDIT1012W" => "95",
              "COMMAUDIT1013W" => "90",
              "COMMAUDIT1014E" => "100",
              "COMMAUDIT1015W" => "80",
              "COMMAUDIT1016E" => "100",
            );

my $advi = -1;
my %advtextx = ();
my $advkey = "";
my $advtext = "";
my $advline;
my %advgotx = ();
my %advrptx = ();

while (<main::DATA>)
{
  $advline = $_;
  $advline =~ s/\x0d//g if $gWin == 0;
  if ($advkey eq "") {
     chomp $advline;
     $advkey = $advline;
     next;
  }
  if (length($advline) >= 14) {
     if ((substr($advline,0,9) eq "COMMAUDIT") or (substr($advline,0,10) eq "COMMREPORT")){
        $advtextx{$advkey} = $advtext;
        chomp $advline;
        $advkey = $advline;
        $advtext = "";
        next;
     }
  }
  $advtext .= $advline;
}
$advtextx{$advkey} = $advtext;

my $anic_ct = 0;
my $itc_ct = 0;

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
                 'KDC_FAMILIES' => 1,
                 'CTIRA_PRIMARY_FALLBACK_INTERVAL' => 1,
                 'KDEB_INTERFACELIST_IPV6' => 1,
                 'KDEB_INTERFACELIST' => 1,
                 'CTIRA_HEARTBEAT' => 1,
                 'CTIRA_HOSTNAME' => 1,
                 'CTIRA_NODETYPE' => 1,
                 'CTIRA_SYSTEM_NAME' => 1,
                 'KDC_PARTITION' => 1,
                 'KDCB0_HOSTNAME' => 1,
              );

my $kdc_families_ct = 0;
my $kde_transport_ct = 0;
my $kdc_partition_ct = 0;

my %porterrx;

my $http_unsup = 0;
my $http_error = 0;
my $gskit_error = 0;
my $ide_error = 0;

my @advimpact = ();
my $rptkey;
my $max_impact = 0;

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
my %environx;
my $environ_ref;
my %rpcrunx;
my @dlogfiles;
my @seg = ();
my @seg_time = ();
my $segi = -1;
my $segp = -1;
my $segcurr = "";
my $segline;
my $segmax = 0;
my $rc;
my $this_hostname;
my $this_system_name;



#  following are the nominal values. These are used to generate an advisories section
#  that can guide usage of the Workload report. These can be overridden by the agentaud.ini file.

my $opt_nohdr;                               # when 1 no headers printed
my $opt_objid;                               # when 1 print object id
my $opt_o;                                   # when defined filename of report file
my $opt_tsit;                                # when defined debug testing sit
my $opt_slot;                                # when defined specify history slots, default 60 minutes
my $opt_pc;
my $opt_inv;
my $opt_instance;                            # when process instanced logs
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
   } elsif ($ARGV[0] eq "-instance") {
      $opt_instance = 1;
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
      $opt_pc = lc $opt_pc;
   } elsif ($ARGV[0] eq "-inv") {
      shift(@ARGV);
      $opt_inv = shift(@ARGV);
      die "Option -inv with no inventory name" if !defined $opt_inv;
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
die "-pc and -inv must not be supplied together\n" if defined $opt_pc and defined $opt_inv;

if (!defined $opt_logpath) {$opt_logpath = "";}
if (!defined $logfn) {$logfn = "";}
if (!defined $opt_z) {$opt_z = 0;}
if (!defined $opt_zop) {$opt_zop = ""}
if (!defined $opt_cmdall) {$opt_cmdall = 0;}
if (!defined $opt_instance) {$opt_instance = 0;}
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
if (!defined $opt_inv) {$opt_inv = "";}
$opt_merge = $opt_allinv;
$opt_instance = 1 if defined $pcinstx{$opt_pc}; # instanced agents have one inv per instance

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

# new report of netstat.info if it can be located

my $netstatpath;
my $netstatfn;
my $gotnet = 0;
$netstatpath = $opt_logpath;
if ( -e $netstatpath . "netstat.info") {
   $gotnet = 1;
   $netstatpath = $opt_logpath;
} elsif ( -e $netstatpath . "../netstat.info") {
   $gotnet = 1;
   $netstatpath = $opt_logpath . "../";
} elsif ( -e $netstatpath . "../../netstat.info") {
   $gotnet = 1;
   $netstatpath = $opt_logpath . "../../";
}
$netstatpath = '"' . $netstatpath . '"';

if ($gotnet == 1) {
   if ($gWin == 1) {
      $pwd = `cd`;
      chomp($pwd);
      $netstatpath = `cd $netstatpath & cd`;
   } else {
      $pwd = `pwd`;
      chomp($pwd);
      $netstatpath = `(cd $netstatpath && pwd)`;
   }

   chomp $netstatpath;

   $netstatfn = $netstatpath . "/netstat.info";
   $netstatfn =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments

   chomp($netstatfn);
   chdir $pwd;

   my $active_line = "";
   my $descr_line = "";
   my @nzero_line;
   my %nzero_ports = (
                        '1918' => 1,
                        '3660' => 1,
                        '63358' => 1,
                        '65100' => 1,
                     );

   my %inbound;
   my $inbound_ref;
   my $high_sendq = 0;
   my $high_recvq = 0;
   my $sendq_ct = 0;
   my $recvq_ct = 0;
   my $total_recvq;
   my $total_sendq;

   #   open( FILE, "< $opt_ini" ) or die "Cannot open ini file $opt_ini : $!";
   if (defined $netstatfn) {
      open NETS,"< $netstatfn" or warn " open netstat.info file $netstatfn -  $!";
      my @nts = <NETS>;
      close NETS;

      # sample netstat outputs

      # Active Internet connections (including servers)
      # PCB/ADDR         Proto Recv-Q Send-Q  Local Address      Foreign Address    (state)
      # f1000e000ca7cbb8 tcp4       0      0  *.*                   *.*                   CLOSED
      # f1000e0000ac93b8 tcp4       0      0  *.*                   *.*                   CLOSED
      # f1000e00003303b8 tcp4       0      0  *.*                   *.*                   CLOSED
      # f1000e00005bcbb8 tcp        0      0  *.*                   *.*                   CLOSED
      # f1000e00005bdbb8 tcp4       0      0  *.*                   *.*                   CLOSED
      # f1000e00005b9bb8 tcp6       0      0  *.22                  *.*                   LISTEN
      # ...
      # Active UNIX domain sockets
      # Active Internet connections (servers and established)
      #
      # Active Internet connections (servers and established)
      # Proto Recv-Q Send-Q Local Address               Foreign Address             State       PID/Program name
      # tcp        0      0 0.0.0.0:1920                0.0.0.0:*                   LISTEN      18382/klzagent
      # tcp        0      0 0.0.0.0:34272               0.0.0.0:*                   LISTEN      18382/klzagent
      # tcp        0      0 0.0.0.0:28002               0.0.0.0:*                   LISTEN      5955/avagent.bin
      # ...
      # Active UNIX domain sockets (servers and established)

      # tcp        0      0 171.128.137.60:20014        0.0.0.0:*                   LISTEN      -
      # tcp        0      0 0.0.0.0:4750                0.0.0.0:*                   LISTEN      -
      # tcp        0      0 171.128.137.60:57290        171.128.137.71:20010        CLOSE_WAIT  -

      my $l = 0;
      my $netstat_state = 0;                 # seaching for "Active Internet connections"
      my $recvq_pos = -1;
      my $sendq_pos = -1;
      foreach my $oneline (@nts) {
         $l++;
         chomp($oneline);
         if ($netstat_state == 0) {           # seaching for "Active Internet connections"
            next if substr($oneline,0,27) ne "Active Internet connections";
            $active_line = $oneline;
            $netstat_state = 1;
         } elsif ($netstat_state == 1) {           # next line is column descriptor line
            $recvq_pos = index($oneline,"Recv-Q");
            $sendq_pos = index($oneline,"Send-Q");
            $descr_line = $oneline;
            $netstat_state = 2;
         } elsif ($netstat_state == 2) {           # collect non-zero send/recv queues
            last if index($oneline,"Active UNIX domain sockets") != -1;
            $oneline =~ /(tcp\S*)\s*(\d+)\s*(\d+)\s*(\S+)\s*(\S+)\s*(\S+)/;
            my $proto = $1;
            if (defined $proto) {
               my $recvq = $2;
               my $sendq = $3;
               my $localad = $4;
               my $foreignad = $5;
               my $istate = $6;
               my $localport = "";
               my $foreignport = "";
               my $localsystem = "";
               my $foreignsystem = "";
               $localad =~ /(\S+)[:\.](\S+)/;
               $localsystem = $1 if defined $1;
               $localport = $2 if defined $2;
               $foreignad =~ /(\S+)[:\.](\S+)/;
               next if substr($foreignad,0,4) eq ":::*";
               $foreignsystem = $1 if defined $1;
               $foreignport = $2 if defined $2;
               if ((defined $nzero_ports{$localport}) or (defined $nzero_ports{$foreignport})) {
                  if (defined $recvq) {
                     if (defined $sendq) {
                        if (($recvq > 0) or ($sendq > 0)) {
                           next if ($recvq == 0) and ($sendq == 0);
                           push @nzero_line,$oneline;
                           $total_sendq += 1;
                           $total_recvq += 1;
                           $sendq_ct += $sendq;
                           $recvq_ct += $recvq;
                           $max_sendq = $sendq if $sendq > $max_sendq;
                           $max_recvq = $recvq if $recvq > $max_recvq;
                           $high_sendq += 1 if $sendq >= 1024;
                           $high_recvq += 1 if $recvq >= 1024;
                        }
                     }
                  }
               }
               if (defined $nzero_ports{$localport}) {
                  if (defined $recvq) {
                     if (defined $sendq) {
                        $foreignsystem =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
                        my $net8 = $1;
                        my $net16 = $2;
                        my $net24 = $3;
                        my $net32 = $4;
                        if ($net8 ne "*") {
                           my $netkey = $net8;
                           my $netrest = $net16 . "." . $net24 . "." . $net32;
                           my $net_ref = $net8x{$netkey};
                           if (!defined $net_ref) {
                              my %netref = (
                                              recv0 => 0,
                                              recvp => 0,
                                              send0 => 0,
                                              sendp => 0,
                                              subnets => {},
                                           );
                              $net_ref = \%netref;
                              $net8x{$netkey} = \%netref;
                           }
                           $net_ref->{recv0} += 1 if $recvq == 0;
                           $net_ref->{recvp} += 1 if $recvq > 0;
                           $net_ref->{send0} += 1 if $sendq == 0;
                           $net_ref->{sendp} += 1 if $sendq > 0;
                           $net_ref->{subnets}{$netrest} += $recvq + $sendq;
                           $netkey = $net8 . "." . $net16;
                           $netrest = $net24 . "." . $net32;
                           $net_ref = $net16x{$netkey};
                           if (!defined $net_ref) {
                              my %netref = (
                                              recv0 => 0,
                                              recvp => 0,
                                              send0 => 0,
                                              sendp => 0,
                                              subnets => {},
                                           );
                              $net_ref = \%netref;
                              $net16x{$netkey} = \%netref;
                           }
                           $net_ref->{recv0} += 1 if $recvq == 0;
                           $net_ref->{recvp} += 1 if $recvq > 0;
                           $net_ref->{send0} += 1 if $sendq == 0;
                           $net_ref->{sendp} += 1 if $sendq > 0;
                           $net_ref->{subnets}{$netrest} += $recvq + $sendq;
                           $netkey = $net8 . "." . $net16 . "." . $net24;
                           $netrest = $net32;
                           $net_ref = $net24x{$netkey};
                           if (!defined $net_ref) {
                              my %netref = (
                                              recv0 => 0,
                                              recvp => 0,
                                              send0 => 0,
                                              sendp => 0,
                                              subnets => {},
                                           );
                              $net_ref = \%netref;
                              $net24x{$netkey} = \%netref;
                           }
                           $net_ref->{recv0} += 1 if $recvq == 0;
                           $net_ref->{recvp} += 1 if $recvq > 0;
                           $net_ref->{send0} += 1 if $sendq == 0;
                           $net_ref->{sendp} += 1 if $sendq > 0;
                           $net_ref->{subnets}{$netrest} += $recvq + $sendq;
                        }
                     }
                  }
               }
               if (defined $nzero_ports{$localport}) {
                  $inbound_ref = $inbound{$localport};
                  if (!defined $inbound_ref) {
                     my %inboundref = (
                                         instances => {},
                                         count => 0,
                                      );
                     $inbound_ref = \%inboundref;
                     $inbound{$localport} = \%inboundref;
                  }
                  $inbound_ref->{count} += 1;
                  $inbound_ref->{instances}{$foreignsystem} += 1;
               }
               if (defined $istate) {
                  if ($istate ne ""){
                     $statex{$istate} += 1;
                     $statei += 1;
                  }
               }
            }
         }
      }
   }
}
my $icw = $statex{"CLOSE_WAIT"};
if (defined $icw) {
   if ($icw > 1000) {
      $advi++;$advonline[$advi] = "Many[$icw] CLOSE_WAIT TCP connection states of $statei connections";
      $advcode[$advi] = "COMMAUDIT1015W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TCP";
   }
}



# new report of dir.info if it can be located

my $dirpath;
my $dirfn;
my $gotdir = 0;
my $this_candlehome = "";
$dirpath = $opt_logpath;
if ( -e $dirpath . "dir.info") {
   $gotdir = 1;
   $dirpath = $opt_logpath;
} elsif ( -e $dirpath . "../dir.info") {
   $gotdir = 1;
   $dirpath = $opt_logpath . "../";
} elsif ( -e $dirpath . "../../dir.info") {
   $gotdir = 1;
   $dirpath = $opt_logpath . "../../";
}
$dirpath = '"' . $dirpath . '"';
if ($gotdir == 1) {
   if ($gWin == 1) {
      $pwd = `cd`;
      chomp($pwd);
      $dirpath = `cd $dirpath & cd`;
   } else {
      $pwd = `pwd`;
      chomp($pwd);
      $dirpath = `(cd $dirpath && pwd)`;
   }
   chomp $dirpath;

   $dirfn = $dirpath . "/dir.info";
   $dirfn =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments

   chomp($dirfn);
   chdir $pwd;

   # Linux/Unix Example
   #CANDLEHOME=/IBM/ITM
   #134552    4 drwxr-xr-x  32 root     root         4096 Sep 23  2019 /opt/IBM/ITM
   #262434    4 drwxrwxrwx   3 root     root         4096 May 29  2015 /opt/IBM/ITM/xmlconfig
   #262678    4 -rwxrwxrwx   1 root     root         1017 Sep 23  2019 /opt/IBM/ITM/xmlconfig/ac16_help.png
   #57385  422 -rwxr-xr-x  1 itmagent  netcool     431450 Aug  6  2018 /opt/IBM/tivoli/ITM/aix536/ms/bin/kdsvlunx
   #
   # Windows Example
   #
   open DINFO,"< $dirfn" or warn " open dir.info file $dirfn -  $!";
   my @din = <DINFO>;
   close DINFO;
   $l = 0;
   my $d1 = "";
   my $d2 = "";
   foreach my $oneline (@din) {
      $l++;
      chomp($oneline);
      next if $oneline eq "";
      if ($this_candlehome eq "") {
         $oneline =~ /CANDLEHOME=(.*)/;
         $this_candlehome = $1 if defined $1;
         next;
      }
      $oneline =~ /\d+\W+\d+\W+(\S+)\W+\d+\W+(\S+)\W+(\S+)\W+(\d+)\W+.{12}\W+(\S+)/;
      my $iperm = $1;
      my $iown = $2;
      my $igroup = $3;
      my $isize = $4;
      my $iname = $5;

      my $key = $iown . "|" . $igroup;
      $owngroupx{$key} += 1;
   }
   if ($this_ihostname ne "") {
      $phdri++;$phdr[$phdri] = "candlehome: $this_candlehome";
   }
   my $og_ct = scalar keys %owngroupx;
   if ($og_ct > 1) {
      my $pog = "";
      foreach $g ( sort {$a cmp $b} keys %owngroupx) {
         $pog .= $g . "[" . $owngroupx{$g} . "] ";
      }
      chop($pog) if $pog ne "";
      $advi++;$advonline[$advi] = "Multiple Owner/Group file instances[$og_ct] $pog";
      $advcode[$advi] = "COMMAUDIT1014E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "FILE";
   }
}

my %instx = ();


$opt_logpath .= '/';
$opt_logpath =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments

die "logpath or logfn must be supplied\n" if !defined $logfn and !defined $opt_logpath;

# Establish nominal values for the Advice Summary section

my $pattern;
my @results = ();
my $inline;
my %todo = ();     # associative array of names and first identified timestamp
my $skipzero = 0;

if ($logfn eq "") {
   @results = ();
   $results[0] = $opt_inv if $opt_inv ne "";
   if ($opt_pc ne "") {
      $pattern = "_ms(_kdsmain)?\\.inv";
      $pattern = "_k" . $opt_pc . "agent\\.inv" if $opt_pc ne "";
      $pattern = "_" . $opt_pc . "_k" . $opt_pc . "cma\\.inv" if $opt_pc eq "nt";
      $pattern = "_" . $opt_pc . "_.*\\.inv" if $opt_pc eq "mq";
      $pattern = "_" . $opt_pc . "_.*\\.inv" if $opt_pc eq "ms";
      opendir(DIR,$opt_logpath) || die("cannot opendir $opt_logpath: $!\n"); # get list of files
      @results = grep {/$pattern/i} readdir(DIR);
      closedir(DIR);
      if ($#results == -1) {
         $pattern = "_" . $opt_pc . "\\.inv";
         opendir(DIR,$opt_logpath) || die("cannot opendir $opt_logpath: $!\n"); # get list of files
         @results = grep {/$pattern/i} readdir(DIR);
         closedir(DIR);
         die "No _*.inv found\n" if $#results == -1;
      }
   }
   if ($opt_instance == 1)      { # instanced agents have one inv per instance
      for my $r (@results) {      # collect them all
         next if substr($r,-4,4) ne ".inv";
         my $ipattern = "(.*)" . "_k" . $opt_pc . "agent\\.inv";
         $r =~ $ipattern;
         my $instance = $1;
         my $testpath = $opt_logpath . $r;
         my %instanceref = (
                              rline => "",           # reference files
                              bline => "",           # base filename
                              instance => $instance, # instance
                           );
         $instx{$r} = \%instanceref;
      }
   } else {
      $logfn =  $results[0];
      if ($#results > 0) {         # more than one inv file - determine which one has most recent date
         my $last_modify = 0;
         $logfn =  $results[0];
         for my $r (@results) {
            next if substr($r,-4,4) ne ".inv";
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
}


# new report of cinfo.info if it can be located

my $cinfopath;
my $cinfofn;
my $gotcin = 0;
$cinfopath = $opt_logpath;
if ( -e $cinfopath . "cinfo.info") {
   $gotcin = 1;
   $cinfopath = $opt_logpath;
} elsif ( -e $cinfopath . "../cinfo.info") {
   $gotcin = 1;
   $cinfopath = $opt_logpath . "../";
} elsif ( -e $cinfopath . "../../cinfo.info") {
   $gotcin = 1;
   $cinfopath = $opt_logpath . "../../";
}
$cinfopath = '"' . $cinfopath . '"';
if ($gotcin == 1) {
   if ($gWin == 1) {
      $pwd = `cd`;
      chomp($pwd);
      $cinfopath = `cd $cinfopath & cd`;
   } else {
      $pwd = `pwd`;
      chomp($pwd);
      $cinfopath = `(cd $cinfopath && pwd)`;
   }
   chomp $cinfopath;

   $cinfofn = $cinfopath . "/cinfo.info";
   $cinfofn =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments

   chomp($cinfofn);
   chdir $pwd;

   # Linux/Unix Example
   #*********** Tue Nov 12 19:19:28 BRT 2019 ******************
   #User: root Groups: root wheel
   #Host name : brlpx3603	 Installer Lvl:06.30.07.06
   #CandleHome: /IBM/ITM
   #Version Format: VV.RM.FF.II (V: Version; R: Release; M: Modification; F: Fix; I: Interim Fix)
   #***********************************************************

   # Windows Example
   #************ Friday, March 06, 2020 08:10:45 AM *************
   #User       : ukc                   Group     : NA
   #Host Name  : PSC-T-TIV01           Installer : Ver: 063007000
   #CandleHome : D:\IBM\ITM
   #Installitm : D:\IBM\ITM\InstallITM
   #*************************************************************
   open CINFO,"< $cinfofn" or warn " open cinfo.info file $cinfofn -  $!";
   my @cin = <CINFO>;
   close CINFO;
   $l = 0;
   my $d1 = "";
   my $d2 = "";
   foreach my $oneline (@cin) {
      $l++;
      chomp($oneline);
      if ($this_ihostname eq "") {
         $oneline =~ /Host name :.*?(\S+).*?Installer Lvl:([0-9\.]*)/ if index($oneline,"Host name") != -1;
         $oneline =~ /Host Name\s*:\s*(\S+)\s*Installer : Ver:\s*([0-9\.]*)/ if index($oneline,"Host Name") != -1;
         $this_ihostname = $1 if defined $1;
         $this_installer = $2 if defined $2;
         if ($this_ihostname ne "") {
            $phdri++;$phdr[$phdri] = "hostname: $this_ihostname";
            $phdri++;$phdr[$phdri] = "Installer: $this_installer";
         }

      # gs   IBM GSKit Security Interface                              li6243  08.00.50.36   d5313a          -               0
      # gs   IBM GSKit Security Interface                              lx8266  08.00.50.69   d6276a          -               0
      } elsif (substr($oneline,0,2) eq "gs") {
         $oneline =~/(3|6)\ .*(\d{2}\.\d{2}\.\d{2}\.\d{2})/;
         my $ibit = $1;
         my $iver = $2;
         if (defined $2) {
            if ($ibit == 3) {
               $this_gskit32 = $iver;
               $phdri++;$phdr[$phdri] = "GSKIT32: $this_gskit32";
            } else {
               $this_gskit64 = $iver;
               $phdri++;$phdr[$phdri] = "GSKIT64: $this_gskit64";
            }
            last if ($this_gskit32 ne "") and ($this_gskit64 ne "")
         }
      # "GS","KGS(64-bit) GSK/IBM GSKit Security Interface","WIX64","080050690","d6276a","KGS64GSK.ver","0"
      # "GS","KGS(32-bit) GSK/IBM GSKit Security Interface","WINNT","080050690","d6276a","KGSWIGSK.ver","0"
      } elsif (substr($oneline,0,2) eq "\"GS\"") {
         $oneline =~  /(WIX64|WINNT)\"\,\"(\d{9})\"/;
         my $ibit = $1;
         my $iver = $2;
         if (defined $2) {
            if ($ibit == "WINNT") {
               $this_gskit32 = $iver;
               $phdri++;$phdr[$phdri] = "GSKIT32: $this_gskit32";
            } else {
               $this_gskit64 = $iver;
               $phdri++;$phdr[$phdri] = "GSKIT64: $this_gskit64";
            }
         }
         last if ($this_gskit32 ne "") and ($this_gskit64 ne "")
      }
   }
}



$pattern = '(\S+)\.env$';
@results = ();
opendir(ENVD,$opt_logpath) || die("cannot opendir $opt_logpath: $!\n"); # get list of files
@results = grep {/$pattern/i} readdir(ENVD);
closedir(ENVD);
my $env_ct;
my @envlines;
my $env_eph = 0;
my $env_anon = 0;
my $env_excl = 0;
my $excl_err = "";
my $eph_err = "";
my $do_env = 1;
if ($#results != -1) {
   $env_ct = $#results + 1;
   foreach my $f (@results) {
      my $full_envfn = $opt_logpath . $f;
      open(ENV,"< $full_envfn") || die("Could not open inv  $full_envfn\n");
      my @envl = <ENV>;
      close(ENV);
      my $l = 0;
      die "empty ENV file $full_envfn\n" if $#envl == -1;
      foreach my $inline (@envl) {
         $l += 1;
         chop($inline);
         if (index($inline,"KDC_FAMILIES=") != -1) {
            my @envdet = ["EPH",$f,$l,$inline];
            push @envlines,\@envdet;
            $kdcx{$inline} = 1;
            $env_eph += 1 if index($inline,"EPHEMERAL:Y") != -1;
         } elsif (index($inline,"KDEB_INTERFACELIST=") != -1){
            $env_excl += 1 if index($inline,"KDEB_INTERFACELIST=!") != -1;
            my @envdet = ["EXCL",$f,$l,$inline];
            push @envlines,\@envdet;
         } elsif (index($inline,"KDEB_INTERFACELIST_IPV6=") != -1){
            $env_excl += 1 if index($inline,"KDEB_INTERFACELIST_IPV6=!") != -1;
            my @envdet = ["EXCL",$f,$l,$inline];
            push @envlines,\@envdet;
         } elsif (index($inline,"KDCB0_HOSTNAME=") != -1){
            my @envdet = ["EXCL",$f,$l,$inline];
            push @envlines,\@envdet;
         } elsif (index($inline,"CT_CMSLIST=") != -1){
            my @envdet = ["CMSL",$f,$l,$inline];
            push @envlines,\@envdet;
            $cmslx{$inline} = 1;
         }
      }
   }
}


####################
if ($env_eph > 0) {
   if ($env_eph != $env_ct) {
      $eph_err = "Conflicting EPHEMERAL:Y Configuration";
   }
}
if ($env_excl > 0) {
   if ($env_excl != $env_ct) {
      $excl_err = "Conflicting Anonymous/Exclusive binds";
   }
}

if ($opt_instance == 1) {
   do_instances();

   $ofn = "logcomm" . "_" . $opt_pc . ".csv";
   open OH, ">$ofn" or die "can't open $ofn: $!";
   print OH "Instance Environment Variable Summary\n";
   print OH "Variable,Instance_ct,Value_ct,Values\n";
   print OH ",File,Line,LogLine,\n";
   foreach my $e (keys %environx) {
      if (($opt_allenv == 1) or (defined $commenvx{$e})) {
         my $environ_ref = $environx{$e};
         $oline = $e . ",";
         $ict = scalar keys %{$environ_ref->{sources}};
         $oline .= $ict . ",";
         $ict = scalar keys %{$environ_ref->{vals}};
         $oline .= $ict . ",";
         my $pvals = "";
         foreach $g (keys %{$environ_ref->{vals}}) {
            $pvals .= $g . "[" . $environ_ref->{vals}{$g} . "] ";
         }
         chop $pvals if $pvals ne "";
         $oline .= $pvals . ",";
         print OH "$oline\n";
         foreach my $s (keys %{$environ_ref->{sources}}) {
            my $source_ref = $environ_ref->{sources}{$s};
            $oline = "," . $s . ",";
            $oline .= $source_ref->{l} . ",";
            $oline .= $source_ref->{line} . ",";
            print OH "$oline\n";
         }
      }
   }

   close OH;

} else {
   do_single();
}


exit 0;

sub do_instances {
   foreach my $r (keys %instx) {
      $instance_ref = $instx{$r};
      $full_logfn = $opt_logpath . $r;
      if ($r =~ /.*\.inv$/) {
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
            $instance_ref->{rline} = $logfn;
            $instance_ref->{bline} = $logbase;
            last;
#           last if $opt_allinv == 0;
         }
      }
      $logbase = $instance_ref->{bline};
      $logfn   = $instance_ref->{rline};
      $loginstance = $instance_ref->{instance};
      print STDERR $opt_pc . " " . $loginstance . "\n";
      do_rpt;
   }
}


sub do_single {
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
}



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
   $segcurr = "";
   $segline = "";
   $segmax = 0;
   %todo = ();
   $kdc_families_ct = 0;
   $kde_transport_ct = 0;
   $kdc_partition_ct = 0;
   $anic_ct = 0;
   $itc_ct = 0;

   $hdri++;$hdr[$hdri] = "Agent Communications Audit report v$gVersion";
   my $audit_start_time = gettime();       # formated current time for report
   $hdri++;$hdr[$hdri] = "Start: $audit_start_time";

   $rc = open_kib();
   return if $rc != 0;

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

      next if length($inline) == 0;
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
      if ($start_date eq "") {
         if (substr($oneline,0,1) eq "+") {
            if (index($oneline,"Start Date:") != -1) {
               $oneline =~ /Start Date: (\d{4}\/\d{2}\/\d{2})/;
               $start_date = $1 if defined $1;
            }
         }
      }

      if ($system_name eq "") {
         if (substr($oneline,0,1) eq "+") {
            if (index($oneline,"System Name:") != -1) {
               $oneline =~ /System Name: (\S+) /;
               $system_name = $1 if defined $1;
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
                        $itc_ct += 1 if $rpc_ref->{'KDE1_stc_t'} eq "1DE0004D";
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
               set_timeline($logtime,$l,$logtimehex,1,"Communications",substr($rest,1));
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
            my $val = $2;
            if (!defined $envx{$ienv}) {
               if (($opt_allenv == 1) or (defined $commenvx{$ienv})) {
                  $envx{$ienv} = $val;
                  set_timeline($logtime,$l,$logtimehex,0,"EnvironmentVariables",substr($rest,1));
               }
               $kdc_families_ct += 1 if $ienv eq "KDC_FAMILIES";
               $kde_transport_ct += 1 if ($ienv eq "KDE_TRANSPORT") and (substr($val,0,12) eq "KDC_FAMILIES");
               $kdc_partition_ct = 1 if ($ienv eq "KDC_PARTITION") and ($val ne '""');
               $this_hostname = $2 if $1 eq "CTIRA_HOSTNAME";
               $this_system_name = $2 if $1 eq "CTIRA_SYSTEM_NAME";
            }
            $env_excl += 1 if index($rest,"KDEB_INTERFACELIST=!") != -1;
            $env_excl += 1 if index($rest,"KDEB_INTERFACELIST_IPV6=!") != -1;
            $environ_ref = $environx{$ienv};
            if (!defined $environ_ref) {
               my %environref = (
                                   sources => {},
                                   vals => {},
                                );
               $environ_ref = \%environref;
               $environx{$ienv} = \%environref;
            }
            $environ_ref->{vals}{$val} += 1;
            my $sourcekey = $clog;
            my $source_ref = $environ_ref->{sources}{$sourcekey};
            if (!defined $source_ref) {
               my %sourceref = (
                                   instance => $loginstance,
                                   log => $clog,
                                   l => $l,
                                   line => $inline,
                               );
               $source_ref = \%sourceref;
               $environ_ref->{sources}{$sourcekey} = \%sourceref;
            }
            next;
         }
      }
      #(5AA2E3F5.0008-13E0:kraaulog.cpp,755,"IRA_OutputLogMsg") Connecting to CMS REMOTE_usrdrtm051ccpr2
      #(6138E582.00B5-2F:kraaulog.cpp,699,"IRA_OutputLogMsg") Self-Describing Agent Register/Install failed with STATUS (1024/SDA Install Blocked) for PRODUCT "SY", with TEMS "HUBTEMS", VERSION_INFO "product_vrmf=06300708;tms_package_vrmf=06300708;tps_package_vrmf=06300708;tpw_package_vrmf=06300708;".
      if (substr($logunit,0,12) eq "kraaulog.cpp") {
         if ($logentry eq "IRA_OutputLogMsg") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; #  Connecting to CMS REMOTE_usrdrtm051ccpr2
            set_timeline($logtime,$l,$logtimehex,0,"OPLOG",substr($rest,1));
            if (substr($rest,1,45) eq "Self-Describing Agent Register/Install failed") {
               $rest =~ /PRODUCT \"(\S+)\".*TEMS \"(\S+)\".*product_vrmf=(\d+)/;
               $isdaproduct = $1;
               $isdatems = $2;
               $isdavrmf = $3;
               $isdafail = 1;   # SDA failure
            }
            next;
         }
      }
      #(5AA2E3F5.0006-13E0:kdcc1wh.c,114,"conv__who_are_you") status=1c010008, "activity not in call", ncs/KDC1_STC_NOT_IN_CALL
      if (substr($logunit,0,9) eq "kdcc1wh.c") {
         if ($logentry eq "conv__who_are_you") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; #  status=1c010008, "activity not in call", ncs/KDC1_STC_NOT_IN_CALL
            set_timeline($logtime,$l,$logtimehex,0,"ANIC",substr($rest,1));
            $anic_ct += 1;
            next;
         }
      }
      #(5AA2E3F1.0000-13E0:kdcc1sr.c,642,"rpc__sar") Endpoint unresponsive: "ip.spipe:#146.89.140.75:3660", 1C010001:1DE0000F, 210, 5(2), FFFF/1, D140831.1:1.1.1.13, tms_ctbs623fp3:d3086a
      #(5AA2E31C.0000-7E4:kdcc1sr.c,642,"rpc__sar") Remote call failure: 1C010001
      #(5AB93569.0000-14C8:kdcc1sr.c,670,"rpc__sar") Connection lost: "ip.spipe:#146.89.140.75:65100", 1C010001:1DE0004D, 30, 100(5), FFFF/40, D140831.1:1.1.1.13, tms_ctbs630fp7:d6305a

      #      RAS1_Printf( RAS1_LINE(This.ccbLineNumber), "%s: "
      #             "\"%s:%lu\", %08lX:%08lX, %u, %lu(%lu), %04X/%lu, %.*s, %s\n",
      #             shortMsg, strName, (unsigned long)port,
      #             (unsigned long)PPFM_STATUS.all, (unsigned long)This.ccbKDE,
      #             elapsedTime, (unsigned long)ifspec->vers, (unsigned long)opn,
      #             pTab->KDCR0_HDR.ahint, (unsigned long)pTab->KDCR0_HDR.seq,
      #             RAS1_LevelStrLen, RAS1_LevelStr,
      #             pCma->cmaCTBLD->valInfo[CTBLD_INFO_DRIVER]);

      if (substr($logunit,0,9) eq "kdcc1sr.c") {
         if ($logentry eq "rpc__sar") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; #  Endpoint unresponsive: "ip.spipe:#146.89.140.75:3660", 1C010001:1DE0000F, 210, 5(2), FFFF/1, D140831.1:1.1.1.13, tms_ctbs623fp3:d3086a
            if (substr($rest,1,19) eq "Remote call failure") { # Endpoint unresponsive: "ip.spipe:#146.89.140.75:3660", 1C010001:1DE0000F, 210, 5(2), FFFF/1, D140831.1:1.1.1.13, tms_ctbs623fp3:d3086a
               my %rpcref = ();
               my $rpckey = $logtime . "|" . $logline;
               $rpcrunx{$rpckey} = \%rpcref;
            } elsif (substr($rest,1,16) eq "Connection lost:") { # Connection lost: "ip.spipe:#146.89.140.75:65100", 1C010001:1DE0004D, 30, 100(5), FFFF/40, D140831.1:1.1.1.13, tms_ctbs630fp7:d6305a
               $rest =~ /\"(\S+)\", (\S+):(\S+), (\d+), (\S+), (\S+), (\S+), (\S+)/;
               my $inameport = $1;    #strNane:port
               my $istatus = $2;      #PPFM_STATUS.all
               my $icode   = $3;      #ccbKDE
               my $ielapsed = $4;     #elapsedTime
               my $iversion = $5;     #ifspec->vers(opn)
               my $ihintseq = $6;     #ahint/seq
               my $ilevel = $7;       #RAS1_LevelStr
               my $ibuild = $8;       #cmaCTBLD->valInfo[CTBLD_INFO_DRIVER])

               my $llost = sec2ltime($logtime+$local_diff);
               my $inotes = "lost[$llost] ";
               $inotes .= 'rmt-endpt' . "[$inameport] " if defined $inameport;
               $inotes .= "elapsed[$ielapsed] " if defined $ielapsed;
               my $msg_ref = "";
               if (defined $icode) {
                  my @msg_ref = $kdemsgx{$icode};
                  my $msg_txt = $msg_ref[0][1] . " \"" . $msg_ref[0][0] . "\"";
                  $inotes .= "$icode $msg_txt]";
                  $itc_ct += 1 if $icode eq "1DE0004D";
               }
               set_timeline($logtime,$l,$logtimehex,2,"RPC-Lost",$inotes);
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
      # (5B8DF983.0000-794:kdhsiqm.c,745,"KDHS_InboundQueueManager") Unsupported request method ""
      # (5B8DF983.0001-794:kdhsiqm.c,747,"KDHS_InboundQueueManager") error in HTTP request from ip.tcp:#172.17.176.201:32652, status=7C4C803A, "unknown method in request"
      if (substr($logunit,0,9) eq "kdhsiqm.c") {
         if ($logentry eq "KDHS_InboundQueueManager") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; # Unsupported request method ""
                        # error in HTTP request from ip.tcp:#172.17.176.201:32652, status=7C4C803A, "unknown method in request"
            $http_unsup += 1 if substr($rest,1,26) eq "Unsupported request method";
            $http_error += 1 if substr($rest,1,21) eq "error in HTTP request";
            set_timeline($logtime,$l,$logtimehex,2,"HTTP",substr($rest,1));
            next;
         }
      }
      # (5B8DF9EF.0002-798:kdebeal.c,81,"ssl_provider_open") GSKit error 402: GSK_ERROR_NO_CIPHERS
      if (substr($logunit,0,9) eq "kdebeal.c") {
         if ($logentry eq "ssl_provider_open") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; # GSKit error 402: GSK_ERROR_NO_CIPHERS
            $gskit_error += 1;
            set_timeline($logtime,$l,$logtimehex,2,"COMM",substr($rest,1));
            next;
         }
      }
      # (5B8DFAD8.0001-2784:kdebp0r.c,240,"receive_pipe") Status 1DE00074=KDE1_STC_DATASTREAMINTEGRITYLOST
      if (substr($logunit,0,9) eq "kdebp0r.c") {
         if ($logentry eq "receive_pipe") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; # Status 1DE00074=KDE1_STC_DATASTREAMINTEGRITYLOST
            $ide_error += 1;
            set_timeline($logtime,$l,$logtimehex,2,"COMM",substr($rest,1));
            next;
         }
      }
      # (5B922710.0037-AB4:kraafmgr.cpp,500,"InitializeRemoteManager") Agent default host address set to 30.132.50.144
      # (5BCDDA1E.001B-5A0:kraafmgr.cpp,2100,"DeriveFullHostname") Full hostname set to "cex_mxoccans02:NT"

      if (substr($logunit,0,12) eq "kraafmgr.cpp") {
         if ($logentry eq "InitializeRemoteManager") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; # Agent default host address set to 30.132.50.144
            set_timeline($logtime,$l,$logtimehex,2,"COMM",substr($rest,1));
            next;
         } elsif ($logentry eq "DeriveFullHostname") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2; # Full hostname set to "cex_mxoccans02:NT"
            set_timeline($logtime,$l,$logtimehex,2,"COMM",substr($rest,1));
            next;
         }
      }


   }
   set_timeline($logtime,$l,$logtimehex,3,"Log","End",);
   if ($anic_ct > 0) {
      $advi++;$advonline[$advi] = "Activity Not in Call count [$anic_ct]";
      $advcode[$advi] = "COMMAUDIT1001W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "COMM";
   }
   if ($itc_ct > 0) {
      $advi++;$advonline[$advi] = "Invalid Transport Correlator error count [$itc_ct]";
      $advcode[$advi] = "COMMAUDIT1002W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "COMM";
   }
   if ($http_unsup > 0) {
      $advi++;$advonline[$advi] = "Unsupported HTTP request methods [$http_unsup]";
      $advcode[$advi] = "COMMAUDIT1003W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "HTTP";
   }
   if ($http_error > 0) {
      $advi++;$advonline[$advi] = "Error HTTP requests[$http_error]";
      $advcode[$advi] = "COMMAUDIT1004W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "HTTP";
   }
   if ($gskit_error > 0) {
      $advi++;$advonline[$advi] = "GSKIT Errors[$gskit_error]";
      $advcode[$advi] = "COMMAUDIT1005W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "COMM";
   }
   if ($ide_error > 0) {
      $advi++;$advonline[$advi] = "KDE Errors[$ide_error]";
      $advcode[$advi] = "COMMAUDIT1006W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "COMM";
   }
   my $idupl = 0;
   if ($kdc_families_ct == 1) {
      if ($kde_transport_ct == 1) {
         my $ikdc = $envx{"KDC_FAMILIES"};
         my $ikde = $envx{"KDE_TRANSPORT"};
         my $ikdce = "KDC_FAMILIES=" . $ikdc;
         my $idupl = ($ikde eq $ikdce);
      }
   }

   if (($kdc_families_ct + $kde_transport_ct) > 1) {
      if ($idupl == 0) {
         $advi++;$advonline[$advi] = "Invalid communication controls - both KDC_FAMILIES and KDE_TRANSPORT are present";
         $advcode[$advi] = "COMMAUDIT1007E";
         $advimpact[$advi] = $advcx{$advcode[$advi]};
         $advsit[$advi] = "COMM";
      }
   }

   if ($kdc_partition_ct == 1) {
      $advi++;$advonline[$advi] = "Unusual configuration KDC_PARTITION specified";
      $advcode[$advi] = "COMMAUDIT1010W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "COMM";
   }

   if ($excl_err ne "") {
      $advi++;$advonline[$advi] = "Conflicting Anonymous/Exclusive binds";
      $advcode[$advi] = "COMMAUDIT1008E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMA";
   }

   if ($eph_err ne "") {
      $advi++;$advonline[$advi] = "Conflicting EPHEMERAL:Y Configuration";
      $advcode[$advi] = "COMMAUDIT1009E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMA";
   }
   my $kdc_ct = scalar keys %kdcx;
   if ($kdc_ct > 1) {
      $advi++;$advonline[$advi] = "Conflicting KDC_FAMILIES settings - See Report COMMREPORT003";
      $advcode[$advi] = "COMMAUDIT1011W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMA";
   }

   my $cmsl_ct = scalar keys %cmslx;
   if ($cmsl_ct > 1) {
      $advi++;$advonline[$advi] = "Conflicting CT_CMSLIST settings - See Report COMMREPORT003";
      $advcode[$advi] = "COMMAUDIT1012W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMA";
   }
   if ($isdafail == 1) {
      $advi++;$advonline[$advi] = "SDA Failure Product[$isdaproduct] TEMS[$isdatems] VRMF[$isdavrmf]";
      $advcode[$advi] = "COMMAUDIT1016E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
   if (defined $this_hostname) {
      if (defined $this_system_name) {
         if ($this_hostname ne $this_system_name) {
            $advi++;$advonline[$advi] = "Conflicting CTIRA_HOSTNAME[$this_hostname] versus CTIRA_SYSTEM_NAME[$this_system_name]";
            $advcode[$advi] = "COMMAUDIT1013W";
            $advimpact[$advi] = $advcx{$advcode[$advi]};
            $advsit[$advi] = "TEMA";
         }
      }
   }

#   # Communication activity timeline
      $rptkey = "COMMREPORT001";$advrptx{$rptkey} = 1;         # record report key
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


      $rptkey = "COMMREPORT002";$advrptx{$rptkey} = 1;         # record report key
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
   if ($do_env == 1) {
      $rptkey = "COMMREPORT003";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: System and Diagnostic ENV report\n";
      $cnt++;$oline[$cnt]="Type,File,LineNum,Line,\n";
      foreach my $h (@envlines) {
         my @ah = @{$h};
         next if $ah[0][0] ne "CMSL";
         $outl = $ah[0][0] . ",";
         $outl .= $ah[0][1] . ",";
         $outl .= $ah[0][2] . ",";
         $outl .= $ah[0][3] . ",";
         $cnt++;$oline[$cnt]="$outl\n";
      }
      foreach my $h (@envlines) {
         my @ah = @{$h};
         next if $ah[0][0] eq "CMSL";
         $outl = $ah[0][0] . ",";
         $outl .= $ah[0][1] . ",";
         $outl .= $ah[0][2] . ",";
         $outl .= $ah[0][3] . ",";
         $cnt++;$oline[$cnt]="$outl\n";
      }
   }

   if ($opt_instance == 1) {
      $opt_o = "logcomm_" . $loginstance . "_" . $opt_pc . ".csv" if $opt_o eq "logcomm.csv";
   } elsif ($opt_pc ne "") {
      $opt_o = "logcomm_" . $opt_pc . ".csv" if $opt_o eq "logcomm.csv";
   }
   my $ofn = $opt_o;
   $ofn = $logbase . "_" . $opt_o if $opt_allinv == 1;

   open OH, ">$ofn" or die "can't open $ofn: $!";

   if ($opt_nohdr == 0) {
      for (my $i=0; $i<=$hdri; $i++) {
         print OH $hdr[$i] . "\n";
      }
      for (my $i=0; $i<=$phdri; $i++) {
         print OH $phdr[$i] . "\n";
      }
   }
   print OH "\n";

   if ($advi != -1) {
      print OH "\n";
      print OH "Advisory Message Report - *NOTE* See advisory notes at report end\n";
      print OH "Impact,Advisory Code,Object,Advisory,\n";
      for (my $a=0; $a<=$advi; $a++) {
          my $mysit = $advsit[$a];
          my $myimpact = $advimpact[$a];
          my $mykey = $mysit . "|" . $a;
          $advx{$mykey} = $a;
      }
      foreach $f ( sort { $advimpact[$advx{$b}] <=> $advimpact[$advx{$a}] ||
                             $advcode[$advx{$a}] cmp $advcode[$advx{$b}] ||
                             $advsit[$advx{$a}] cmp $advsit[$advx{$b}] ||
                             $advonline[$advx{$a}] cmp $advonline[$advx{$b}]
                           } keys %advx ) {
         my $j = $advx{$f};
         next if $advimpact[$j] == -1;
         print OH "$advimpact[$j],$advcode[$j],$advsit[$j],$advonline[$j]\n";
         $max_impact = $advimpact[$j] if $advimpact[$j] > $max_impact;
         $advgotx{$advcode[$j]} = $advimpact[$j];
      }
   } else {
      print OH "No Expert Advisory messages\n";
   }

   print OH "\n";
   print OH "System Name: $system_name\n\n" if $system_name ne "";

   for (my $i = 0; $i<=$cnt; $i++) {
      print OH $oline[$i];
   }

   if ($advi != -1) {
      print OH "\n";
      print OH "Advisory Trace, Meaning and Recovery suggestions follow\n\n";
      foreach $f ( sort { $a cmp $b } keys %advgotx ) {
         next if substr($f,0,9) ne "COMMAUDIT";
         print OH "Advisory code: " . $f  . "\n";
         print OH "Impact:" . $advgotx{$f}  . "\n";
         print STDERR "$f missing\n" if !defined $advtextx{$f};
         print OH $advtextx{$f};
      }
   }

   my $rpti = scalar keys %advrptx;
   if ($rpti != -1) {
      print OH "\n";
      print OH "Agent Communications Audit report - Meaning and Recovery suggestions follow\n\n";
      foreach $f ( sort { $a cmp $b } keys %advrptx ) {
         next if !defined $advrptx{$f};
         print STDERR "$f missing\n" if !defined $advtextx{$f};
         print OH "$f\n";
         print OH $advtextx{$f};
      }
   }
   close(OH);
$opt_o = "logcomm.csv";          # trigger proper filename if re-entered on instanced agent
   close(ZOP) if $opt_zop ne "";
}


sub open_kib {
   # get list of files
   if (-e $logfn) {
         $segi += 1;
         $seg[$segi] = $logfn;
         $segmax = 0;
         $clog = $logfn;
   } else {
      my $elogfiles;

      $logpat = $logbase . '-.*\.log' if defined $logbase;
      opendir(DIR,$opt_logpath) || die("cannot opendir $opt_logpath: $!\n");
      @elogfiles = readdir(DIR);
      closedir(DIR);
      my @ilogfiles;
      foreach my $f (@elogfiles) {
         push @ilogfiles,$f if $f =~ /$logpat/i;
      }
      if ($#ilogfiles == -1) {
         warn "no log files found with given specifcation $logpat\n";
         return 1;
      }

      my $dlog;          # fully qualified name of diagnostic log
      my $oneline;       # local variable
      my $tlimit = 100;  # search this many times for a timestamp at begining of a log
      my $t;
      my $tgot;          # track if timestamp found
      my $itime;

      foreach $f (@ilogfiles) {
         $f =~ /^.*-(\d+)\.log/;
         $segmax = $1 if $segmax == 0;
         $segmax = $1 if $segmax < $1;
         $dlog = $opt_logpath . $f;
         $clog = $f;
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
   return 0;
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
# 0.51000 - Correct syntax error, missing double quote
# 0.52000 - Convert to Advisory/Report structure.
# 0.53000 - Capture RPC-Lost messages, which have a different form
# 0.54000 - Capture Port Scanning type messages
# 0.55000 - Advisory on mixed KDC_FAMILIES and KDE_TRANSPORT
# 0.56000 - Add Default host address to timeline
# 0.57000 - Add in system name and some CTIRA variables if present
# 0.58000 - Add in ENV checking if the files are present
# 0.59000 - Add in KDC_PARTITION checking - rare and usually an error
# 0.60000 - Add advisory for different CTIRA_HOSTNAME and CTIRA_SYSTEM_NAME
# 0.61000 - Add hostname/installer/gskit_level when cinfo.info is available
# 0.62000 - Make KDE_TRANSPORT/KDC_FAMILIES check work on Windows
# 0.63000 - Handle instanced logs
# 0.64000 - Add advisory for Linux/Unix different owner/group files
# 0.65000 - Add advisory too many CLOSE_WAIT connections
# 0.66000 - Add advisory on SDA install failure
__END__

COMMAUDIT1001W
Text: Activity Not in Call count [count]

Tracing: error
(5AA2E3F5.0006-13E0:kdcc1wh.c,114,"conv__who_are_you") status=1c010008, "activity not in call", ncs/KDC1_STC_NOT_IN_CALL

Meaning: This is a strong signal of a duplicate agent case.
ITM uses remote procedure calls to do most of communications
and this error means that the partner in the communication process
has made a mistake. One example would be a "call completion"
that did not correspond with any outstanding RPC at the agent.

Recovery plan: Investigate the TEMS the agent connects
to for evidence of duplicate agents - especially this one -
and resolve the issue.
--------------------------------------------------------------

COMMAUDIT1002W
Text: Invalid Transport Correlator error count [count]

Tracing: error
+5B6B15BF.0001     e-secs: 0                  mtu: 944         KDE1_stc_t: 1DE0004D

Meaning: This is a strong signal of a duplicate agent case.
ITM uses remote procedure calls to do most of communications
and this error means that the partner in the communication process
rejected the attempted communication because the type of communication
did not match. For example a ip.pipe communication was sent
but the partner knew it needed a ip.spipe. It could also be a
conflict between a simple connection and a EPHEMERAL:Y connection
or many other cases.

Recovery plan: Investigate the TEMS the agent connects
to for evidence of duplicate agents - especially this one -
and resolve the issue.
--------------------------------------------------------------

COMMAUDIT1003W
Text: Unsupported HTTP request methods [count]

Tracing: error
(5B8E17E5.0000-794:kdhsiqm.c,745,"KDHS_InboundQueueManager") Unsupported request method "TRACE"

Meaning: This is a strong signal that the agent is being
subject to port scan testing. ITM does not defend against
such activities. See this document for a statement:

APM: Port scanner usage and known limitations with IBM Tivoli Monitoring
https://www.ibm.com/developerworks/community/blogs/0587adbc-8477-431f-8c68-9226adea11ed/entry/Port_scanner_usage_and_known_limitations_with_IBM_Tivoli_Monitoring?lang=en

On agents, the impact can be reduced by setting HTTP_SERVER:N so as
not to run the internal web server. Also EPHEMERAL:Y will eliminate the
Agent listening port. That is not always possible but if you cannot
convince your security team to exempt ITM processes, it will reduce
the impact.

Recovery plan: Investigate and eliminate usage of port
scan testing.
--------------------------------------------------------------

COMMAUDIT1004W
Text: Error HTTP requests[count]

Tracing: error
(5B8E17E5.0000-794:kdhsiqm.c,745,"KDHS_InboundQueueManager") Unsupported request method "TRACE"

Meaning: This is a strong signal that the agent is being
subject to port scan testing. ITM does not defend against
such activities. See this document for a statement:

APM: Port scanner usage and known limitations with IBM Tivoli Monitoring
https://www.ibm.com/developerworks/community/blogs/0587adbc-8477-431f-8c68-9226adea11ed/entry/Port_scanner_usage_and_known_limitations_with_IBM_Tivoli_Monitoring?lang=en

On agents, the impact can be reduced by setting HTTP_SERVER:N so as
not to run the internal web server. Also EPHEMERAL:Y will eliminate the
Agent listening port. That is not always possible but if you cannot
convince your security team to exempt ITM processes, it will reduce
the impact.

Recovery plan: Investigate and eliminate usage of port
scan testing.
--------------------------------------------------------------

COMMAUDIT1005W
Text: GSKIT Errors[count]

Tracing: error
(5B8E17F3.0000-798:kdebeal.c,81,"ssl_provider_open") GSKit error 402: GSK_ERROR_NO_CIPHERS

Meaning: This is a strong signal that the agent is being
subject to port scan testing. ITM does not defend against
such activities. See this document for a statement:

APM: Port scanner usage and known limitations with IBM Tivoli Monitoring
https://www.ibm.com/developerworks/community/blogs/0587adbc-8477-431f-8c68-9226adea11ed/entry/Port_scanner_usage_and_known_limitations_with_IBM_Tivoli_Monitoring?lang=en

On agents, the impact can be reduced by setting HTTP_SERVER:N so as
not to run the internal web server. Also EPHEMERAL:Y will eliminate the
Agent listening port. That is not always possible but if you cannot
convince your security team to exempt ITM processes, it will reduce
the impact.

Recovery plan: Investigate and eliminate usage of port
scan testing.
--------------------------------------------------------------

COMMAUDIT1006W
Text: KDE Errors[count]

Tracing: error
(5B8E0245.0001-146C:kdebp0r.c,240,"receive_pipe") Status 1DE00074=KDE1_STC_DATASTREAMINTEGRITYLOST

Meaning: This is a communication error. If the error name is
KDE1_STC_DATASTREAMINTEGRITYLOST, this is a strong signal that
the agent is being subject to port scan testing. ITM does not defend
against such activities. See this document for a statement:

APM: Port scanner usage and known limitations with IBM Tivoli Monitoring
https://www.ibm.com/developerworks/community/blogs/0587adbc-8477-431f-8c68-9226adea11ed/entry/Port_scanner_usage_and_known_limitations_with_IBM_Tivoli_Monitoring?lang=en

On agents, the impact can be reduced by setting HTTP_SERVER:N so as
not to run the internal web server. Also EPHEMERAL:Y will eliminate the
Agent listening port. That is not always possible but if you cannot
convince your security team to exempt ITM processes, it will reduce
the impact.

Recovery plan: Investigate and eliminate usage of port
scan testing. If this is not port scanning, work with IBM support
to diagnose and resolve the issue.
--------------------------------------------------------------

COMMAUDIT1007E
Text: Invalid communication controls - both KDC_FAMILIES and KDE_TRANSPORT are present

Tracing: error

Meaning: An ITM process should have only one communication string
defined. There should be an environment variable KDC_FAMILIES or
an environment variable KDE_TRANSPORT.

When both are present, one part of ITM communications uses one
and another part uses the other. This often leads to communication
errors and agent malfunction. Sometimes it barely struggles along
but usually there is a severe error like unable to connect to the
historical data collector WPA or HD agent.

Recovery plan: Configure the agent to use just one communications
control. If this is not obvious, work with IBM support to diagnose
and resolve the issue.
--------------------------------------------------------------

COMMAUDIT1008E
Text: Conflicting Anonymous/Exclusive binds

Tracing: error

There are several agents present. Some have exclusive binds as
seen by the KDEB_INTERFACELIST=!xx.xx.xx.xx and some do not. This
creates an serious configuration issue where communications from
one agent can cancel another agent's communication.

Whenever exclusive bind is used, all ITM process must use that
exclusive bind in a coordinated fashion.

If anonymous bind is used no use of KDEB_INTERFACELIST=! etc, all
ITM processes must use anonymous bind.

Recovery plan: Configure the agents to use just one KDEB_INTERFACELIST
correctly. If this is not obvious, work with IBM support to diagnose
and resolve the issue.
--------------------------------------------------------------

COMMAUDIT1009E
Text: Conflicting EPHEMERAL:Y Configuration

Tracing: error

Meaning: EPHEMERAL:Y is a way to configure an agent to work with
the TEMS and a WPA on the TEMS system without requiring any
obvious TCP listening ports.

If there are multiple ITM Agents on a system, they should all use
EPHEMERAL:Y or all not use it. If that is violated communications
will fail randomly.

Note that TEMS/WPA/TEPS can never use EPHEMERAL:Y. If set that
way they cannot function.

There is log which can allow a single agent with EPHEMERAL:Y to
work OK with a single other agent without EPHEMERAL:Y. However
that could fail any time a third agent is installed. Therefore
best practice is to configure them all one way or the other.

Recovery plan: Configure the agents to use all EPHEMERAL:Y or all
without that.
--------------------------------------------------------------

COMMAUDIT1010W
Text: Unusual configuration KDC_PARTITION specified

Tracing: error

Meaning: KDC_PARTITION was an early way to project ITM communications
beyond a single firewall. It is rarely seen and usually means
a configuration error. If communication errors are being observed
then this should be checked. In several cases the value was 0

Recovery plan: Reconfigure ITM process without partition setting null.
--------------------------------------------------------------

COMMAUDIT1011W
Text: Conflicting KDC_FAMILIES settings - See Report COMMREPORT003

Tracing: error

Meaning: KDC_FAMILIES specifies how an agent should connect to a
TEMS [hub or remote]. If these are different it could be a
configuration accident.

Recovery plan: Review the agent configuration to make sure they
are consistent with what is required.
--------------------------------------------------------------

COMMAUDIT1012W
Text: Conflicting CT_CMSLIST settings - See Report COMMREPORT003

Tracing: error

Meaning: CT_CMSLIST specifies the systems where a TEMS will be
found where the agent connects. If these are different it could be a
configuration accident.

Recovery plan: Review the agent configuration to make sure they
are consistent with what is required.
--------------------------------------------------------------

COMMAUDIT1013W
Text: Conflicting CTIRA_HOSTNAME[name] versus CTIRA_SYSTEM_NAME[name]

Tracing: error

Meaning: CTIRA_HOSTNAME defines the agent name as TEMS sees it.
CITRA_HOST_NAME defines the agent name as seen in the TEP Navigator.
When they are different, an element of confusion arises which can
slow diagnosis time.

Recovery plan: Review the agent configuration and make sure that
CTIRA_HOSTNAME and CTIRA_SYSTEM_NAME are the same.
--------------------------------------------------------------

COMMAUDIT1014E
Text: Multiple Owner/Group file instances[count] list[count] ...

Tracing: error

Meaning: If present, the dir.info is scanned. A normal install
on Linux/Unix will use the same owner and group for all files.
This records the case when they are different.

Recovery plan: Change the owner/group files so they are indentical
within the installation directory.
--------------------------------------------------------------

COMMAUDIT1015W
Text: Many[count] CLOSE_WAIT TCP connection states of count connections

Tracing: netstat.info file from pdcollect

Meaning: This comes from a case where an enormous number of
CLOSE_WAIT state connections had built up....

TCP,Many[56435] CLOSE_WAIT TCP connection states of 56667 connections

as a result, an ITM agent could not get temporary/ephemeral ports
and failed to connnect to the TEMS. These CLOSE_WAIT connections were from
an unrelated product.

[A TCP expert will cring at the following simplification of a complex logic.]

These CLOSE_WAIT state connections are normal. When a TCP socket connection
is closed, the TCP system places it in CLOSE_WAIT status for 120 seconds [default].
The goal is so make it easier to handle late arriving/duplicate/fragmented packets.

It is possible to change that 120 second timeout, which was after all defined
in the early days of TCP in 1981.

Recovery plan: Investigate and change the server process leaving so many
CLOSE_WAIT connections. Or run that server on another system.
--------------------------------------------------------------

COMMAUDIT1016E
Text: SDA Failure Product[productcode] TEMS[tems] VRMF[maintlevel]

Tracing: error

Meaning: The agent is attempting to register a maintenance level
using SDA or Self Describing Agent logic. The TEMS only allows
certained defined maintenance levels and this one is not permitted.

Recovery plan example:
1) First log into the TEMS
    ./tacmd login -s hostname

2) Then disable all SDA functions so that nothing will happen while
making configuration changes below
    ./tacmd suspendsda

3) Run this command and get the current version of the MQ agent which
will be needed in the next step (this may need to be run on the agent,
I'm not sure)
    ./tacmd listsystems  -d

4) Turn on SDA for the agent that you want to enable it for, I think in
your case this will be the MQ agent, and put the 8 character version
(from step 3 above) after the -v parameter, I'm not sure what this value
is so I just put in 06300000 for now, just replace it with the right
value
    ./tacmd addsdainstalloptions -t MQ -v 06300000

5) use this command to verify which agents are set to use SDA (you
should see MQ here since the above step enabled it)
    ./tacmd listsdainstalloptions

6) turn SDA back on so that
    ./tacmd resumesda

7) At this point you can use this command to see if the application
support for the MQ agent got updated
    ./tacmd listappinstallrecs

8) Restore to pre-630 logic
  ./tacmd addSdaInstallOptions -t default -i on
--------------------------------------------------------------

COMMREPORT001
Text: Timeline of TEMS connectivity

Sample Report
LocalTime,Hextime,Line,Advisory/Report,Notes,
20180808115304,Log,Start
20180808115305,REMOTE_odibmp003,ip.spipe:#151.171.86.23[3660],Connecting to TEMS,
20180808120935,REMOTE_odibmp003,ip.spipe:#151.171.86.23[3660],reconnect to TEMS REMOTE_odibmp003 without obvious comm failure after 0/00:16:30,

Meaning: A high level summary of Agent to TEMS connectivity. This
case involved an agent that was constantly losing connectivity.

Recovery plan: Investigate further. If needed, work with IBM Support.
----------------------------------------------------------------

COMMREPORT002
Text: Timeline of Communication events

Sample Report
LocalTime,Hextime,Line,Advisory/Report,Notes,
20180808115304,5B6B11E0,18,Log,Start,
20180808115304,5B6B11E0,70,EnvironmentVariables,KDE_TRANSPORT=KDC_FAMILIES="HTTP_CONSOLE:N HTTP_SERVER:N HTTP:0 ip.spipe port:3660 ip.pipe use:n sna use:n ip use:n ip6.pipe use:n ip6.spipe use:n ip6 use:n HTTP_SERVER:N",
20180808115304,5B6B11E0,74,EnvironmentVariables,KDEB_INTERFACELIST="!151.171.33.235",
20180808115305,5B6B11E1,1149,ANIC,14fe484587be.42.02.97.ab.21.eb.7e.b5: 1,1,5B4B1265,5B4B1265,
20180808115305,5B6B11E1,1167,ANIC,14fe4845886c.42.02.97.ab.21.eb.7e.b5: 1,1,5B4B1265,5B4B1265,

Meaning: A detailed report on communication events

Recovery plan: Investigate further. If needed, work with IBM Support.
----------------------------------------------------------------

COMMREPORT003
Text: System ENV report

Sample Report
Type,File,LineNum,Line,
EPH,5h.env,48,KDC_FAMILIES=ip.spipe HTTP_SERVER:N
,EPH,70.env,47,KDC_FAMILIES=ip.spipe HTTP_SERVER:N
,EPH,lz.env,42,KDC_FAMILIES=ip.spipe port:3660 ip.pipe port:1918 ip use:n sna use:n EPHEMERAL:Y HTTP_SERVER:N
,EPH,ul.env,40,KDC_FAMILIES=ip.spipe port:3660 ip.pipe port:1918 ip use:n sna use:n EPHEMERAL:Y HTTP_SERVER:N

Meaning: When a KDEB_INTERFACELIST or EPHEMERAL:Y conflict is seen, this report shows the
relevant lines in the env files.

Recovery plan: Investigate further. If needed, work with IBM Support.
----------------------------------------------------------------
