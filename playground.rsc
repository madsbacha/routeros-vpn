:do {
  :global "DEBUG_LOG_METHOD_CALLS" true;
  :global "DEBUG_LOG" true;
  :global printMethodCall do={
    :global "DEBUG_LOG_METHOD_CALLS";
    :local name [:tostr $1];
    :if ($"DEBUG_LOG_METHOD_CALLS" = true) do={
      :put "Calling method $name";
    }
  }
  :global printDebug do={
    :global "DEBUG_LOG";
    :local msg $1;
    :if ($"DEBUG_LOG" = true) do={
      :put $msg;
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

  :global PIAGetToken do={
    :global printMethodCall;
    :global printDebug;
    :global "PIA_getMetaServer_fromServerRegion";
    $printMethodCall "PIAGetToken";

    :local serverRegion $1;
    :local metaServer [$"PIA_getMetaServer_fromServerRegion" $serverRegion];
    $printDebug ($metaServer->"cn");
    $printDebug ($metaServer->"ip");
    :return $metaServer;
  };

  :do {
    :local PIAServers [$loadServersFromFile "pia-servers.txt"];
    :local region "de_berlin";
    :put "Setting up VPN for server region $region";
    :local serverRegion [$PIAGetRegionFromServers $PIAServers $region];
    :put [$PIAGetToken $serverRegion];
  };
}