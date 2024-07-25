:do {
  :local fetchServers do={
    :local fileName [ :tostr $1 ];
    :local maxChunkSize 32768;
    :put "Max chunk size: $maxChunkSize";

    :local fileSize [/file/get $fileName size];
    :put "Total file size: $fileSize";

    :local offset ($fileSize - $maxChunkSize);
    :put "Offset: $offset";

    :local content [([/file/read file=$fileName chunk-size=$maxChunkSize offset=$offset as-value]->"data")];
    :local contentLen [:len $content];
    :put "Read content of length: $contentLen";

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
      :put "Filesize $fileSize";
      :local chunkSize ($fileSize - $readOffset);
      :if ($chunkSize > 32768) do={:set chunkSize 32768};
      :if ($chunkSize < 1) do={:set chunkSize 1};
      :put "Reading from $readOffset with length $chunkSize";
      :local partialRead [([/file/read offset=$readOffset chunk-size=$chunkSize file=$fileName as-value]->"data")];
      :set jsonString ($jsonString . $partialRead);
      :set readOffset ($readOffset + $chunkSize);
      :put "Should repeat ($readOffset < $fileSize): $[($readOffset < $fileSize)]"
    };
    :local jsonStringLen [:len $jsonString];
    :return [:deserialize from=json value=$jsonString];
  }
  :put [$fetchServers "pia-servers.txt"]
}