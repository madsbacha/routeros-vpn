:do {
  :global "PIA_USERNAME" "";
  :global "PIA_PASSWORD" "";

  :global "WG_INTERFACE" "vpn-pia-berlin-1";

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

    if ([:tostr $valueArg] = "") do={
      :return $defaultArg;
    }

    :return $valueArg;
  }

  :global required do={
    :global withDefault;

    :local valueArg $1
    :local nameArg [$withDefault value=$name default="UNKNOWN"];

    if ([:tostr $valueArg] = "") do={
      :error ("The argument " . $nameArg . " is required.");
    }

    :return $valueArg;
  }

  :global CanSuccessfullyPingOnInterface do={
    :global withDefault;
    :global printMethodCall;
    :global printVar;
    :global required;

    :local interfaceArg [:tostr [$required $interface name="interface"]];
    :local addressArg [:tostr [$required $address name="address"]];
    :local countArg 1;

    $printMethodCall "CanSuccessfullyPingOnInterface";
    $printVar name="interface" value=$interfaceArg;
    $printVar name="address" value=$addressArg;
    $printVar name="count" value=$countArg;

    :do {
      :local result [/ping interface=$interfaceArg address=$addressArg count=$countArg as-value];
      return ($result->"status" != "timeout");
    } on-error={
      return false;
    }
  }

  :global loadServersFromFile do={
    :global printMethodCall;
    :global required;

    :local fileName [ :tostr [$required $1 name="fileName"] ];

    $printMethodCall "loadServersFromFile";

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

    $printMethodCall "PIAGetRegionFromServers";
    
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

    $printMethodCall "PIA_getMetaServer_fromServerRegion";

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

    $printMethodCall "PIA_getWireGuardServer_fromServerRegion";

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

    $printMethodCall "PIA_getWireGuardPort_fromServers";

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

    $printMethodCall "CreateBasicAuthValue";

    :return [:convert [(($usernameArg . ":") . $passwdArg)] to=base64];
  };

  :global CreateBasicAuthHeader do={
    :global printMethodCall;
    :global CreateBasicAuthValue;
    :global printVar;
    :global required

    :local usernameArg [:tostr [$required $username name="username"]];
    :local passwdArg [:tostr [$required $passwd name="passwd"]];

    $printMethodCall "CreateBasicAuthHeader";

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

    $printMethodCall "SetStaticDnsEntry";
    $printVar name="name" value=$nameStr;
    $printVar name="address" value=$addressStr;
    $printVar name="comment" value=$commentStr;

    :local existing [/ip/dns/static/find name=$nameStr];
    $printVar name="existing" value=$existing;
    :if ($existing = "") do={
      $printDebug ("No existing DNS entry exist for " . $nameStr);
      $printDebug ("Creating static DNS entry for " . $nameStr);
      /ip/dns/static/add name=$nameStr address=$addressStr comment=$commentStr;
    };
    :if ($existing != "") do={
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

    $printMethodCall "RemoveStaticDnsEntry";
    $printVar name="nameArg" value=$nameArg;

    :local existing [/ip/dns/static/find name=$nameArg];
    :if ($existing != "") do={
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

    $printMethodCall "DoDelay";
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
    :global "PIA_USERNAME";
    :global "PIA_PASSWORD";
    :global SetStaticDnsEntry;
    :global RemoveStaticDnsEntry;
    :global DoDelay;
    :global required;

    :local serverRegion [$required $1 name="1"];

    $printMethodCall "PIAGetToken";
    $printVar name=PIA_USERNAME value=$"PIA_USERNAME";
    $printVar name=PIA_PASSWORD value=$"PIA_PASSWORD";

    :local metaServer [$"PIA_getMetaServer_fromServerRegion" $serverRegion];
    :local metaCommonName ($metaServer->"cn");
    :local metaIp ($metaServer->"ip");
    $printVar name=metaCommonName value=$metaCommonName;
    $printVar name=metaIp value=$metaIp;

    :local tokenUrlPath "/authv3/generateToken";
    :local tokenUrl ("https://" . $metaCommonName . $tokenUrlPath);
    $printVar name=tokenUrl value=$tokenUrl;
    :local authHeader [$CreateBasicAuthHeader username=$"PIA_USERNAME" passwd=$"PIA_PASSWORD"];
    $printVar name=authHeader value=$authHeader;
    $SetStaticDnsEntry name=$metaCommonName address=$metaIp comment="Temporary entry for PIA VPN Script";
    $DoDelay 1s;
    :local result [/tool/fetch url=$tokenUrl mode=https http-method=get http-header-field=$authHeader as-value output=user];
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

    $printMethodCall "EnsureWireGuardInterfaceExists";
    $printVar name="nameArg" value=$nameArg;

    :local existing [/interface/wireguard/find name=$nameArg];
    :if ($existing = "") do={
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

    $printMethodCall "GetPublicKeyForWireGuardInterface";
    $printVar name="nameArg" value=$nameArg;

    :local existing [/interface/wireguard/get [find name=$nameArg]];

    :return ($existing->"public-key");
  }

  :global "PIA_AddWireGuardKey" do={
    :global printMethodCall;
    :global printDebug;
    :global printVar;
    :global required;

    :local serverIpArg [:tostr [$required $serverIp name="serverIp"]];
    :local serverPortArg [:tostr [$required $serverPort name="serverPort"]];
    :local serverCommonNameArg [:tostr [$required $serverCommonName name="serverCommonName"]];
    :local piaTokenArg [:tostr [$required $piaToken name="piaToken"]];
    :local publicKeyArg [:tostr [$required $publicKey name="publicKey"]];

    $printMethodCall "PIA_AddWireGuardKey";
    $printVar name="serverIpArg" value=$serverIpArg;
    $printVar name="serverPortArg" value=$serverPortArg;
    $printVar name="serverCommonNameArg" value=$serverCommonNameArg;
    $printVar name="piaTokenArg" value=$piaTokenArg;
    $printVar name="publicKeyArg" value=$publicKeyArg;

    :local piaTokenEncoded [:convert to=url $piaTokenArg];
    :local publicKeyEncoded [:convert to=url $publicKeyArg];

    :local keyUrl ((((((("https://" . $serverIpArg) . ":") . $serverPortArg) . "/addKey?pt=") . $piaTokenEncoded) . "&pubkey=") . $publicKeyEncoded);
    $printVar name="keyUrl" value=$keyUrl;

    $SetStaticDnsEntry name=$serverCommonNameArg address=$serverIpArg \
      comment="Temporary entry for PIA VPN Script";
    $DoDelay 1s;

    :local result [/tool/fetch url=$keyUrl mode=https http-method=get as-value output=user];
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

    $printMethodCall "ClearAllPeersOnInterface";
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
    :local commentArg [:tostr [$withDefault $comment default="PIA VPN Peer"]];

    $printMethodCall "AddWireGuardPeerToInterface";

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

    $printMethodCall "ClearAllAddressesOnInterface";
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

    $printMethodCall "SetAddressOnInterface";

    /ip/address/add address=$addressArg network=$networkArg \
      interface=$interfaceArg comment="PIA VPN Address";
  };

  :do {
    :local canPing [$CanSuccessfullyPingOnInterface interface=$"WG_INTERFACE" address=1.1.1.1];
    if ($canPing) do={
      :put "PIA VPN is running.";
      :return true;
    }

    :local PIAServers [$loadServersFromFile "pia-servers.txt"];
    :local region "de_berlin";
    :put "Setting up VPN for server region $region";
    :local serverRegion [$PIAGetRegionFromServers $PIAServers $region];

    # Login to PIA and retrieve a token.
    :local piaToken [$PIAGetToken $serverRegion];

    :local wireguardServer [$"PIA_getWireGuardServer_fromServerRegion" $serverRegion];
    :local wireguardPort [$"PIA_getWireGuardPort_fromServers" $PIAServers];

    $EnsureWireGuardInterfaceExists $"WG_INTERFACE";
    :local publicKey [$GetPublicKeyForWireGuardInterface $"WG_INTERFACE"];

    # Add our public key to the PIA servers.
    :local addKeyResult [$"PIA_AddWireGuardKey" serverIp=($wireguardServer->"ip") \
      serverPort=$wireguardPort serverCommonName=($wireguardServer->"cn") \
      piaToken=$piaToken publicKey=$publicKey];

    # Setup the PIA peer on the WireGuard interface.
    $ClearAllPeersOnInterface interface=($"WG_INTERFACE");
    $AddWireGuardPeerToInterface interface=($"WG_INTERFACE") \
      endpointAddress=($addKeyResult->"server_ip") endpointPort=($wireguardPort) \
      publicKey=($addKeyResult->"server_key") allowedAddress="0.0.0.0/0" \
      persistentKeepalive=25s;

    # Setup the PIA VPN address on the WireGuard interface.
    $ClearAllAddressesOnInterface interface=($"WG_INTERFACE");
    $SetAddressOnInterface interface=($"WG_INTERFACE") \
      network=($addKeyResult->"server_vip") address=($addKeyResult->"peer_ip");
  };
}