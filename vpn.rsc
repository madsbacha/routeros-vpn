:do {
  :global "DEBUG_LOG_METHOD_CALLS" true;
  :global "DEBUG_LOG" true;
  :global printMethodCall do={
    :global "DEBUG_LOG_METHOD_CALLS";
    :local name [:tostr $1];
    :if ($"DEBUG_LOG_METHOD_CALLS" = true) do={
      :put "DEBUG | Calling method $name";
    }
  }
  :global printDebug do={
    :global "DEBUG_LOG";
    :local msg $1;
    :if ($"DEBUG_LOG" = true) do={
      :put $msg;
    }
  }
  :global printVar do={
    :global "DEBUG_LOG";
    if ($"DEBUG_LOG" = true) do={
      :put "DEBUG | $name = $value";
    }
  }

  :global withDefault do={
    :local valueArg $value;
    :local defaultArg $default;

    if ([:typeof $valueArg] = "nothing") do={
      :return $defaultArg;
    }

    :return $valueArg;
  }

  :global required do={
    :global withDefault;

    :local valueArg $1
    :local nameArg [$withDefault value=$name default="UNKNOWN"];
    :local descriptionArg [$withDefault value=$description default=""];

    if ([:typeof $valueArg] = "nothing") do={
      :error ("The argument " . $nameArg . " is required. " . $descriptionArg);
    }

    :return $valueArg;
  }

  :global ParseBool do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;

    :local firstArg [$required $1 name="first argument"];

    $printMethodCall $0;
    $printVar name="first" value=$firstArg;

    :local boolValue [:tobool $firstArg];
    :if ([:typeof $boolValue] = "bool") do={
      :return $boolValue;
    }

    :if ($firstArg = "true" or $firstArg = "True" or $firstArg = "TRUE" or $firstArg = "1" \
          or $firstArg = "y" or $firstArg = "Y" or $firstArg = "yes" or $firstArg = "YES" \
          or $firstArg = true) do={
      :return true;
    }
    :return false;
  }

  :global FileIsOlderThan do={
    :global required;
    :global printMethodCall;
    :global printVar;

    :local fileArg [:tostr [$required $file name="file" description="Path to a file."]];
    :local ageArg [:totime [$required $age name="age" description="The age to check against the last-modified time of the file."]];

    $printMethodCall $0;

    $printVar name="fileArg" value=$fileArg;
    $printVar name="ageArg" value=$ageArg;

    :local currentDate [:totime [/system/clock/get date]];
    :local currentTime [:totime [/system/clock/get time]];
    :local currentDateTime ($currentDate + $currentTime);
  
    :local fileDateTime;
    :do {
        :set fileDateTime [:totime [/file/get $fileArg value-name=last-modified]];
        $printVar name="fileDateTime" value=$fileDateTime;
    } on-error={
        :put "ERROR: Unable to retrieve last-modified time for file '$fileArg'.";
        :return true;
    }

    :local fileAge ($currentDateTime - $fileDateTime);
    $printVar name="fileAge" value=$fileAge;

    :local isOlderThan ($ageArg < $fileAge);
    $printVar name="isOlderThan" value=$isOlderThan;
    :return $isOlderThan;
  }

  :global FileExists do={
    :global printMethodCall;
    :global printVar;
    :global required;

    :local filePathArg [:tostr [$required $file name="file" description="The file to check if it exists."]];

    $printMethodCall $0;

    :return ([:len [/file/find name=$filePathArg]] > 0);
  }

  :global CanSuccessfullyPingOnInterface do={
    :global withDefault;
    :global printMethodCall;
    :global printVar;
    :global required;

    :local interfaceArg [:tostr [$required $interface name="interface"]];
    :local addressArg [:tostr [$required $address name="address"]];
    :local countArg 1;

    $printMethodCall $0;
    $printVar name="interface" value=$interfaceArg;
    $printVar name="address" value=$addressArg;
    $printVar name="count" value=$countArg;

    :do {
      :local result [/ping interface=$interfaceArg address=$addressArg count=$countArg as-value];
      return ([:typeof ($result->"status")] = "nothing");
    } on-error={
      return false;
    }
  }

  :global loadServersFromFile do={
    :global printMethodCall;
    :global required;

    :local fileName [ :tostr [$required $1 name="fileName"] ];

    $printMethodCall $0;

    :local maxChunkSize 32768;

    :local fileSize [/file/get $fileName size];
    :local offset ($fileSize - $maxChunkSize);

    :local content [([/file/read file=$fileName chunk-size=$maxChunkSize offset=$offset as-value]->"data")];
    :local contentLen [:len $content];

    :local excessContentSize 0;
    :local foundJson false;
    :local startFrom 0;

    while (!$foundJson and $excessContentSize < $maxChunkSize) do={
      :set startFrom [($contentLen - $excessContentSize)];

      :local excessContent [:pick $content $startFrom $contentLen];
      :set foundJson ([:len [:find $excessContent "}"]] > 0);
      :if (!$foundJson) do={
        :set excessContentSize ($excessContentSize + 1);
      };
    };
    :set excessContentSize ($excessContentSize - 1);

    :set fileSize ([/file/get $fileName size] - $excessContentSize);
    :local jsonString "";
    :local readOffset 0;
    :while ($readOffset <= $fileSize) do={
      :local chunkSize ($fileSize - $readOffset);
      :if ($chunkSize > 32768) do={:set chunkSize 32768};
      :if ($chunkSize < 1) do={:set chunkSize 1};
      :local partialRead [([/file/read offset=$readOffset chunk-size=$chunkSize file=$fileName as-value]->"data")];
      :set jsonString ($jsonString . $partialRead);
      :set readOffset ($readOffset + $chunkSize);
    };
    :local jsonStringLen [:len $jsonString];
    :return [:deserialize from=json value=$jsonString];
  };

  :global PIAGetRegionFromServers do={
    :local servers $1;
    :local region [:tostr $2];

    :global printMethodCall;

    $printMethodCall $0;
    
    :foreach k,v in=($servers->"regions") do={
      :local regionId ($v->"id");
      :if ($regionId = $region) do={
        :return $v
      };
    };
    :return false;
  }

  :global "PIA_getMetaServer_fromServerRegion" do={
    :global printMethodCall;
    :global printDebug;
    :global required;
    
    :local serverRegion [$required $1 name="serverRegion"];

    $printMethodCall $0;

    :local metaServers ($serverRegion->"servers"->"meta");
    $printDebug "Found these meta servers:";
    $printDebug $metaServers;
    :local metaServer ($metaServers->0);
    $printDebug "Choosing the first meta server:";
    $printDebug $metaServer;
    :return $metaServer;
  };

  :global "PIA_getWireGuardServer_fromServerRegion" do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;

    :local serverRegionArg [$required $1 name="serverRegion"];

    $printMethodCall $0;

    :local wireguardServers ($serverRegionArg->"servers"->"wg");
    $printDebug "Found these wireguard servers: ";
    $printDebug $wireguardServers;
    :local wireguardServer ($wireguardServers->0);
    $printDebug "Choosing the first wireguard server:";
    $printDebug $wireguardServer;
    :return $wireguardServer;
  }

  :global "PIA_getWireGuardPort_fromServers" do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;

    :local serversArg [$required $1 name="servers"];

    $printMethodCall $0;

    :local ports ($serversArg->"groups"->"wg"->0->"ports");
    $printDebug "Found these wireguard ports: ";
    $printDebug $ports;
    :local port ($ports->0);
    $printDebug "Choosing the first wireguard port:";
    $printDebug $port;
    return $port;
  }

  :global CreateBasicAuthValue do={
    :global printMethodCall;
    :global required;

    :local usernameArg [:tostr [$required $username name="username"]];
    :local passwdArg [:tostr [$required $passwd name="passwd"]];

    $printMethodCall $0;

    :return [:convert [(($usernameArg . ":") . $passwdArg)] to=base64];
  };

  :global CreateBasicAuthHeader do={
    :global printMethodCall;
    :global CreateBasicAuthValue;
    :global printVar;
    :global required

    :local usernameArg [:tostr [$required $username name="username"]];
    :local passwdArg [:tostr [$required $passwd name="passwd"]];

    $printMethodCall $0;

    :local value [$CreateBasicAuthValue username=$usernameArg passwd=$passwdArg];
    :return [("Authorization: Basic " . $value)];
  }

  :global SetStaticDnsEntry do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;

    :local nameStr [:tostr [$required $name name="name"]];
    :local addressStr [:tostr [$required $address name="address"]];
    :local commentStr [:tostr [$required $comment name="comment"]];

    $printMethodCall $0;
    $printVar name="name" value=$nameStr;
    $printVar name="address" value=$addressStr;
    $printVar name="comment" value=$commentStr;

    :local existing [/ip/dns/static/find name=$nameStr];
    $printVar name="existing" value=$existing;
    :if ([:len $existing] = 0) do={
      $printDebug ("No existing DNS entry exist for " . $nameStr);
      $printDebug ("Creating static DNS entry for " . $nameStr);
      /ip/dns/static/add name=$nameStr address=$addressStr comment=$commentStr;
    } else={
      $printDebug ("Found existing static DNS entry for " . $nameStr);
      $printDebug ("Upading existing static DNS entry for " . $nameStr);
      /ip/dns/static/set [find name=$nameStr] address=$addressStr comment=$commentStr;
    };
    $printDebug ("Added static dns entry " . $nameStr);
  }

  :global RemoveStaticDnsEntry do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;

    :local nameArg [:tostr [$required $name name="name"]];

    $printMethodCall $0;
    $printVar name="nameArg" value=$nameArg;

    :local existing [/ip/dns/static/find name=$nameArg];
    :if ([:len $existing] != 0) do={
      /ip/dns/static/remove [find name=$nameArg]
    };
    $printDebug ("Removed static dns entry " . $nameArg);
  }

  :global DoDelay do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;

    :local seconds [:tostr [$required $1 name="1"]];

    $printMethodCall $0;
    $printDebug (("Delaying " . $seconds) . " seconds");
    $printVar name="seconds" value=$seconds;

    :delay $seconds;
  }

  :global PIAGetToken do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global CreateBasicAuthHeader;
    :global "PIA_getMetaServer_fromServerRegion";
    :global SetStaticDnsEntry;
    :global RemoveStaticDnsEntry;
    :global DoDelay;
    :global required;
    :global ParseBool;
    :global InstallPIACertificate;
    :global withDefault;

    :local serverRegion [$required $1 name="1"];
    :local piaUsernameArg [$required $"pia-username" name="pia-username"];
    :local piaPasswdArg [$required $"pia-password" name="pia-password"];
    :local verifyCertificateArg [$ParseBool [$withDefault value=$"verify-pia-certificate" default=true]];
    :local installCertificateArg [$ParseBool [$withDefault value=$"install-pia-certificate" default=true]];

    $printMethodCall $0;
    $printVar name="pia-username" value=$piaUsernameArg;
    $printVar name="pia-password" value=$piaPasswdArg;
    $printVar name="verify-pia-certificate" value=$verifyCertificateArg;
    $printVar name="install-pia-certificate" value=$installCertificateArg;

    :local metaServer [$"PIA_getMetaServer_fromServerRegion" $serverRegion];
    :local metaCommonName ($metaServer->"cn");
    :local metaIp ($metaServer->"ip");
    $printVar name=metaCommonName value=$metaCommonName;
    $printVar name=metaIp value=$metaIp;

    :local verifyCertificateValue "yes";
    :if ($verifyCertificateArg) do={
      :if ($installCertificateArg) do={
        $InstallPIACertificate;
      }
    } else={
      :set $verifyCertificateValue "no";
    }

    :local tokenUrlPath "/authv3/generateToken";
    :local tokenUrl ("https://" . $metaCommonName . $tokenUrlPath);
    $printVar name=tokenUrl value=$tokenUrl;
    :local authHeader [$CreateBasicAuthHeader username=$piaUsernameArg passwd=$piaPasswdArg];
    $printVar name=authHeader value=$authHeader;
    $SetStaticDnsEntry name=$metaCommonName address=$metaIp comment="Temporary entry for PIA VPN Script";
    $DoDelay 1s;
    :local result [/tool/fetch url=$tokenUrl mode=https check-certificate=$verifyCertificateValue http-method=get http-header-field=$authHeader as-value output=user];
    $printVar name="result" value=$result;
    $RemoveStaticDnsEntry name=$metaCommonName;

    :if ($result->"status" != "finished") do={
      :put "Fetch failed to retrieve token from PIA";
      :put $result;
      :return false;
    }
    :local tokenJson [:deserialize from=json ($result->"data")];
    if ($tokenJson->"status" != "OK") do={
      :put ("Received invalid status from PIA when fetching token: " . ($tokenJson->"status"));
      :put ($tokenJson->"message");
      :return false;
    }

    :return ($tokenJson->"token");
  };

  :global EnsureWireGuardInterfaceExists do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;

    :local nameArg [:tostr [$required $1 name="1"]];

    $printMethodCall $0;
    $printVar name="nameArg" value=$nameArg;

    :local existing [/interface/wireguard/find name=$nameArg];
    :if ([:len $existing] = 0) do={
      /interface/wireguard/add name=$nameArg;
      $printDebug ("Added WireGuard interface " . $nameArg);
    };
  }

  :global GetPublicKeyForWireGuardInterface do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;
    
    :local nameArg [:tostr [$required $1 name="1"]];

    $printMethodCall $0;
    $printVar name="nameArg" value=$nameArg;

    :local existing [/interface/wireguard/get [find name=$nameArg]];

    :return ($existing->"public-key");
  }

  :global "PIA_AddWireGuardKey" do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;
    :global DoDelay;
    :global ParseBool;
    :global InstallPIACertificate;
    :global withDefault;
    :global SetStaticDnsEntry;
    :global RemoveStaticDnsEntry;

    :local serverIpArg [:tostr [$required $serverIp name="serverIp"]];
    :local serverPortArg [:tostr [$required $serverPort name="serverPort"]];
    :local serverCommonNameArg [:tostr [$required $serverCommonName name="serverCommonName"]];
    :local piaTokenArg [:tostr [$required $piaToken name="piaToken"]];
    :local publicKeyArg [:tostr [$required $publicKey name="publicKey"]];
    :local verifyCertificateArg [$ParseBool [$withDefault value=$"verify-pia-certificate" default=true]];
    :local installCertificateArg [$ParseBool [$withDefault value=$"install-pia-certificate" default=true]];

    $printMethodCall $0;
    $printVar name="serverIpArg" value=$serverIpArg;
    $printVar name="serverPortArg" value=$serverPortArg;
    $printVar name="serverCommonNameArg" value=$serverCommonNameArg;
    $printVar name="piaTokenArg" value=$piaTokenArg;
    $printVar name="publicKeyArg" value=$publicKeyArg;
    $printVar name="verify-pia-certificate" value=$verifyCertificateArg;
    $printVar name="install-pia-certificate" value=$installCertificateArg;

    :local verifyCertificateValue "yes";
    :if ($verifyCertificateArg) do={
      :if ($installCertificateArg) do={
        $InstallPIACertificate;
      }
    } else={
      :set $verifyCertificateValue "no";
    }

    :local piaTokenEncoded [:convert to=url $piaTokenArg];
    :local publicKeyEncoded [:convert to=url $publicKeyArg];

    :local keyUrl ((((((("https://" . $serverCommonNameArg) . ":") . $serverPortArg) . "/addKey?pt=") . $piaTokenEncoded) . "&pubkey=") . $publicKeyEncoded);
    $printVar name="keyUrl" value=$keyUrl;

    $SetStaticDnsEntry name=$serverCommonNameArg address=$serverIpArg \
      comment="Temporary entry for PIA VPN Script";
    $DoDelay 1s;

    :local result [/tool/fetch url=$keyUrl mode=https check-certificate=$verifyCertificateValue http-method=get as-value output=user];
    $printVar name="result" value=$result;

    $RemoveStaticDnsEntry name=$serverCommonNameArg;

    :if ($result->"status" != "finished") do={
      :put "Fetch failed to add WireGuard public key to PIA";
      :put $result;
      :return false;
    }
    :local dataJson [:deserialize from=json ($result->"data")];
    if ($dataJson->"status" != "OK") do={
      :put ("Received invalid status from PIA when adding WireGuard public key: " . ($dataJson->"status"));
      :put ($dataJson->"message");
      :return false;
    }

    :return $dataJson;
  };

  :global ClearAllPeersOnInterface do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;

    :local interfaceArg [:tostr [$required $interface name="interface"]];

    $printMethodCall $0;
    $printVar name="interface" value=$interfaceArg;

    /interface/wireguard/peers/remove [find interface=$interfaceArg];
  }

  :global AddWireGuardPeerToInterface do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;
    :global withDefault;
    :global ClearAllPeersOnInterface;

    :local interfaceArg [:tostr [$required $interface name="interface"]];
    :local endpointAddressArg [:tostr [$required $endpointAddress name="endpointAddress"]];
    :local endpointPortArg [:tostr [$required $endpointPort name="endpointPort"]];
    :local publicKeyArg [:tostr [$required $publicKey name="publicKey"]];
    :local allowedAddressArg [:tostr [$required $allowedAddress name="allowedAddress"]];
    :local persistentKeepaliveArg [:tostr [$required $persistentKeepalive name="persistentKeepalive"]];
    :local commentArg [:tostr [$withDefault value=$comment default="PIA VPN Peer"]];

    $printMethodCall $0;

    /interface/wireguard/peers/add interface=$interfaceArg \
      endpoint-address=$endpointAddressArg \
      endpoint-port=$endpointPortArg \
      allowed-address=$allowedAddressArg \
      public-key=$publicKeyArg \
      persistent-keepalive=$persistentKeepaliveArg \
      comment=$commentArg;
  };

  :global ClearAllAddressesOnInterface do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;

    :local interfaceArg [:tostr [$required $interface name="interface"]];

    $printMethodCall $0;
    $printVar name="interface" value=$interfaceArg;

    /ip/address/remove [find interface=$interfaceArg];
  }

  :global SetAddressOnInterface do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;

    :local interfaceArg [:tostr [$required $interface name="interface"]];
    :local addressArg [:tostr [$required $address name="address"]];
    :local networkArg [:tostr [$required $network name="network"]];

    $printMethodCall $0;

    /ip/address/add address=$addressArg network=$networkArg \
      interface=$interfaceArg comment="PIA VPN Address";
  };

  :global PIAFetchServers do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;
    :global DoDelay;

    $printMethodCall $0;

    :local dstPathArg [:tostr [$required $"dst-path" name="dst-path"]];

    /tool/fetch url="https://serverlist.piaservers.net/vpninfo/servers/v4" mode=https dst-path=$dstPathArg
    $DoDelay 1s;
  }

  :global InstallPIACertificate do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global DoDelay;

    $printMethodCall $0;

    :local existing [/certificate/find common-name="Private Internet Access"];
    :if ([:len $existing] = 0) do={
      :put "Installing PIA CA Certificate...";
      :local dstPath "pia-ca.rsa.4096.crt";
      /tool/fetch "https://raw.githubusercontent.com/pia-foss/manual-connections/refs/heads/master/ca.rsa.4096.crt" dst-path=$dstPath;
      $DoDelay 1s;
      /certificate/import file-name=$dstPath;
    };
  }

  :global SetupWireGuard do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;
    :global withDefault;
    :global loadServersFromFile;
    :global PIAGetRegionFromServers;
    :global PIAGetToken;
    :global "PIA_getWireGuardServer_fromServerRegion";
    :global "PIA_getWireGuardPort_fromServers";
    :global GetPublicKeyForWireGuardInterface;
    :global "PIA_AddWireGuardKey";
    :global EnsureWireGuardInterfaceExists;
    :global ClearAllPeersOnInterface;
    :global AddWireGuardPeerToInterface;
    :global ClearAllAddressesOnInterface;
    :global SetAddressOnInterface;
    :global ParseBool;

    :local interfaceArg [:tostr [$required $interface name="interface" description="The name of the WireGuard interface to create/use for the VPN connection."]];
    :local regionArg [:tostr [$required $region name="region" description="The PIA VPN region to use for this VPN connection."]];
    :local piaUsernameArg [$required $"pia-username" name="pia-username" description="Your PIA username."];
    :local piaPasswdArg [$required $"pia-password" name="pia-password" description="Your PIA password."];
    :local serversFilePathArg [:tostr [$withDefault value=$"servers-file-path" default="pia-servers.txt"]];
    :local verifyCertificateArg [$ParseBool [$withDefault value=$"verify-pia-certificate" default=true]];
    :local installCertificateArg [$ParseBool [$withDefault value=$"install-pia-certificate" default=true]];

    $printMethodCall $0;

    :local PIAServers [$loadServersFromFile $serversFilePathArg];
    :put "Setting up VPN for server region $region";
    :local serverRegion [$PIAGetRegionFromServers $PIAServers $regionArg];

    # Login to PIA and retrieve a token.
    :local piaToken [$PIAGetToken $serverRegion pia-username=$piaUsernameArg pia-password=$piaPasswdArg \
      verify-pia-certificate=$verifyCertificateArg install-pia-certificate=$installCertificateArg];

    :local wireguardServer [$"PIA_getWireGuardServer_fromServerRegion" $serverRegion];
    :local wireguardPort [$"PIA_getWireGuardPort_fromServers" $PIAServers];

    $EnsureWireGuardInterfaceExists $interfaceArg;
    :local publicKey [$GetPublicKeyForWireGuardInterface $interfaceArg];

    # Add our public key to the PIA servers.
    :local addKeyResult [$"PIA_AddWireGuardKey" serverIp=($wireguardServer->"ip") \
      serverPort=$wireguardPort serverCommonName=($wireguardServer->"cn") \
      piaToken=$piaToken publicKey=$publicKey verify-pia-certificate=$verifyCertificateArg \
      install-pia-certificate=$installCertificateArg];

    # Setup the PIA peer on the WireGuard interface.
    $ClearAllPeersOnInterface interface=($interfaceArg);
    $AddWireGuardPeerToInterface interface=($interfaceArg) \
      endpointAddress=($addKeyResult->"server_ip") endpointPort=($wireguardPort) \
      publicKey=($addKeyResult->"server_key") allowedAddress="0.0.0.0/0" \
      persistentKeepalive=25s;

    # Setup the PIA VPN address on the WireGuard interface.
    $ClearAllAddressesOnInterface interface=($interfaceArg);
    $SetAddressOnInterface interface=($interfaceArg) \
      network=($addKeyResult->"server_vip") address=($addKeyResult->"peer_ip");
  }

  :global EnsureVPNMasquerading do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;

    :local interfaceArg [:tostr [$required $interface name="interface" description="The name of the WireGuard interface to create a src masquerade rule for."]];

    $printMethodCall $0;

    :local existing [/ip/firewall/nat/find out-interface=$interfaceArg];
    :if ([:len $existing] = 0) do={
      /ip/firewall/nat/add chain=srcnat action=masquerade out-interface=$interfaceArg comment="PIA VPN: Masquerade outgoing traffic";
    };
  }

  :global Portforward do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;

    $printMethodCall $0;
    # TODO: Port portforwarding.
  }

  :global SetupVPN do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;
    :global withDefault;
    :global FileIsOlderThan;
    :global CanSuccessfullyPingOnInterface;
    :global FileExists;
    :global PIAFetchServers;
    :global DoDelay;
    :global SetupWireGuard;
    :global Portforward;
    :global ParseBool;
    :global EnsureVPNMasquerading;
    :global PIAGetToken;
    :global PIAGetRegionFromServers;
    :global loadServersFromFile;

    :local interfaceArg [:tostr [$required $interface name="interface" description="The name of the WireGuard interface to create/use for the VPN connection."]];
    :local regionArg [:tostr [$required $region name="region" description="The PIA VPN region to use for this VPN connection."]];
    :local piaUsernameArg [$required $"pia-username" name="pia-username" description="Your PIA username."];
    :local piaPasswdArg [$required $"pia-password" name="pia-password" description="Your PIA password."];
    :local pingAddressArg [:tostr [$withDefault value=$"ping-address" default=1.1.1.1]];
    :local serversFilePathArg [:tostr [$withDefault value=$"servers-file-path" default="pia-servers.txt"]];
    :local piaServersTTLArg [:totime [$withDefault value=$"pia-servers-ttl" default=24h]];
    :local setupMasqueradeArg [$ParseBool [$withDefault value=$"masquerade" default=true]];
    :local verifyCertificateArg [$ParseBool [$withDefault value=$"verify-pia-certificate" default=true]];
    :local installCertificateArg [$ParseBool [$withDefault value=$"install-pia-certificate" default=true]];
    :local shouldPortForwardArg [$ParseBool [$withDefault value=$"port-forward" default=false]];
    :local portForwardToArg nothing;

    :if ($shouldPortForwardArg) do={
      :set portForwardToArg [:tostr [$required $"port-forward-to" name="port-forward-to" description="The local address to forward port-traffic to."]];
    }

    $printMethodCall $0;
    $printVar name="interface" value=$interfaceArg;
    $printVar name="region" value=$regionArg;
    $printVar name="pia-username" value=$piaUsernameArg;
    $printVar name="pia-password" value=$piaPasswdArg;
    $printVar name="ping-address" value=$pingAddressArg;
    $printVar name="servers-file-path" value=$serversFilePathArg;
    $printVar name="pia-servers-ttl" value=$piaServersTTLArg;
    $printVar name="masquerade" value=$setupMasqueradeArg;
    $printVar name="verify-pia-certificate" value=$verifyCertificateArg;
    $printVar name="install-pia-certificate" value=$installCertificateArg;
    $printVar name="port-forward" value=$shouldPortForwardArg;
    $printVar name="port-forward-to" value=$portForwardToArg;

    :local canPing [$CanSuccessfullyPingOnInterface interface=$interfaceArg address=$pingAddressArg];
    :if ($canPing) do={
      :put "PIA VPN is running.";
    } else={
      :put "PIA VPN is not running.";
    }

    # TODO: Verify certificates for all fetch calls.
    # TODO: DNS Setup
    :if (![$FileExists file=$serversFilePathArg]) do={
      $PIAFetchServers dst-path=$serversFilePathArg;
    }

    :if ([$FileIsOlderThan file=$serversFilePathArg age=$piaServersTTLArg]) do={
      :put "Updating PIA server list...";
      $PIAFetchServers dst-path=$serversFilePathArg;
    }

    :if (!$canPing) do={
      $SetupWireGuard interface=$interfaceArg \
        region=$regionArg \
        pia-username=$piaUsernameArg \
        pia-password=$piaPasswdArg \
        servers-file-path=$serversFilePathArg \
        verify-pia-certificate=$verifyCertificateArg install-pia-certificate=$installCertificateArg;
      $DoDelay 1s;
      :set canPing [$CanSuccessfullyPingOnInterface interface=$interfaceArg address=$pingAddressArg];
    }

    :if ($setupMasqueradeArg) do={
      $EnsureVPNMasquerading interface=$interfaceArg;
    }

    :if ($canPing and $shouldPortForwardArg) do={
      :put "Port forwarding...";
      $Portforward;
    }
  };

  :do {
    $SetupVPN interface="vpn-pia-berlin-1" region="de_berlin" \
      pia-username="" pia-password="";
  }
}
