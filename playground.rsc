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

  :global loadServersFromFile do={
    :global printMethodCall;
    $printMethodCall "loadServersFromFile";

    :local fileName [ :tostr $1 ];
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
    :global printMethodCall;
    $printMethodCall "PIAGetRegionFromServers";

    :local servers $1;
    :local region [:tostr $2];
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
    $printMethodCall "PIA_getMetaServer_fromServerRegion";

    :local serverRegion $1;
    :local metaServers ($serverRegion->"servers"->"meta");
    $printDebug "Found these meta servers:";
    $printDebug $metaServers;
    :local metaServer ($metaServers->0);
    $printDebug "Choosing the first meta server:";
    $printDebug $metaServer;
    :return $metaServer;
  };

  :global "PIA_getWireGuardServer_fromServerRegion" do={
    :local serverRegionArg $1;

    :global printMethodCall;
    :global printDebug;
    :global printVar;
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
    :local serversArg $1;

    :global printMethodCall;
    :global printDebug;
    :global printVar;
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
    :local usernameArg [:tostr $username];
    :local passwdArg [:tostr $passwd];

    :global printMethodCall;

    $printMethodCall "CreateBasicAuthValue";

    :return [:convert [(($usernameArg . ":") . $passwdArg)] to=base64];
  };

  :global CreateBasicAuthHeader do={
    :local usernameArg [:tostr $username];
    :local passwdArg [:tostr $passwd];

    :global printMethodCall;
    :global CreateBasicAuthValue;
    :global printVar;

    $printMethodCall "CreateBasicAuthHeader";

    :local value [$CreateBasicAuthValue username=$usernameArg passwd=$passwdArg];
    :return [("Authorization: Basic " . $value)];
  }

  :global SetStaticDnsEntry do={
    :local nameStr [:tostr $name];
    :local addressStr [:tostr $address];
    :local commentStr [:tostr $comment];

    :global printMethodCall;
    :global printVar;

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
    :global printDebug;
    $printDebug ("Added static dns entry " . $nameStr);
  }

  :global RemoveStaticDnsEntry do={
    :local nameArg [:tostr $name];

    :global printMethodCall;
    :global printDebug;
    :global printVar;

    $printMethodCall "RemoveStaticDnsEntry";
    $printVar name="nameArg" value=$nameArg;

    :local existing [/ip/dns/static/find name=$nameArg];
    :if ($existing != "") do={
      /ip/dns/static/remove [find name=$nameArg]
    };
    $printDebug ("Removed static dns entry " . $nameArg);
  }

  :global DoDelay do={
    :local seconds [:tostr $1];

    :global printDebug;
    :global printVar;

    $printDebug (("Delaying " . $seconds) . " seconds");
    $printVar name="seconds" value=$seconds;

    :delay $seconds;
  }

  :global PIAGetToken do={
    :global printMethodCall;
    $printMethodCall "PIAGetToken";
    :global printDebug;
    :global printVar;
    :global CreateBasicAuthHeader;
    :global "PIA_getMetaServer_fromServerRegion";
    :global "PIA_USERNAME";
    :global "PIA_PASSWORD";
    :global SetStaticDnsEntry;
    :global RemoveStaticDnsEntry;
    :global DoDelay;

    $printVar name=PIA_USERNAME value=$"PIA_USERNAME";
    $printVar name=PIA_PASSWORD value=$"PIA_PASSWORD";

    :local serverRegion $1;
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
    :local nameArg [:tostr $1];

    :global printMethodCall;
    :global printDebug;
    :global printVar;

    $printMethodCall "EnsureWireGuardInterfaceExists";
    $printVar name="nameArg" value=$nameArg;

    :local existing [/interface/wireguard/find name=$nameArg];
    :if ($existing = "") do={
      /interface/wireguard/add name=$nameArg;
      $printDebug ("Added WireGuard interface " . $nameArg);
    };
  }

  :global GetPublicKeyForWireGuardInterface do={
    :local nameArg [:tostr $1];

    :global printMethodCall;
    :global printDebug;
    :global printVar;

    $printMethodCall "GetPublicKeyForWireGuardInterface";
    $printVar name="nameArg" value=$nameArg;

    :local existing [/interface/wireguard/get [find name=$nameArg]];

    :return ($existing->"public-key");
  }

  :global "PIA_AddWireGuardKey" do={
    :local serverIpArg [:tostr $serverIp];
    :local serverPortArg [:tostr $serverPort];
    :local serverCommonNameArg [:tostr $serverCommonName];
    :local piaTokenArg [:tostr $piaToken];
    :local publicKeyArg [:tostr $publicKey];

    :global printMethodCall;
    :global printDebug;
    :global printVar;

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

    $SetStaticDnsEntry name=$serverCommonNameArg address=$serverIpArg comment="Temporary entry for PIA VPN Script";
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

  :do {
    :local PIAServers [$loadServersFromFile "pia-servers.txt"];
    :local region "de_berlin";
    :put "Setting up VPN for server region $region";
    :local serverRegion [$PIAGetRegionFromServers $PIAServers $region];
    :local piaToken [$PIAGetToken $serverRegion];
    :local wireguardServer [$"PIA_getWireGuardServer_fromServerRegion" $serverRegion];
    :local wireguardPort [$"PIA_getWireGuardPort_fromServers" $PIAServers];
    $EnsureWireGuardInterfaceExists $"WG_INTERFACE";
    :local publicKey [$GetPublicKeyForWireGuardInterface $"WG_INTERFACE"];
    :local addKeyResult [$"PIA_AddWireGuardKey" serverIp=($wireguardServer->"ip") serverPort=$wireguardPort serverCommonName=($wireguardServer->"cn") piaToken=$piaToken publicKey=$publicKey]
    :put $addKeyResult;
  };
}