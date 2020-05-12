
SELECT
    *,
    coalesce(releasedate, startdate) AS pubdate
    FROM (
      SELECT
        t.id,
        t.source,
        t.source_id,
        t.json -> 'releases' -> 0 ->> 'ocid' AS ocid,
        t.json -> 'releases' -> 0 -> 'tag' AS release_tag,
        releases ->> 'language' AS language,
        releases -> 'tender' ->> 'title' AS title,
        releases -> 'tender' ->> 'description' AS description,
        releases -> 'tender' -> 'value' ->> 'amount' AS value,
        releases -> 'tender' -> 'value' ->> 'currency' AS currency,
        f_cast_isots(NULLIF((((t.json -> 'releases'::text) -> 0) ->> 'date'::text), ''::text)) AS releasedate,
        f_cast_isots(NULLIF((((((t.json -> 'releases'::text) -> 0) -> 'tender'::text) -> 'tenderPeriod'::text) ->> 'startDate'::text), ''::text)) AS startdate,
        f_cast_isots(NULLIF((((((t.json -> 'releases'::text) -> 0) -> 'tender'::text) -> 'tenderPeriod'::text) ->> 'endDate'::text), ''::text)) AS enddate,
        t.json -> 'releases' -> 0 -> 'buyer' ->> 'name' AS buyer,
        releases -> 'buyer' -> 'address' ->> 'streetAddress' AS streetAddress,
        releases -> 'buyer' -> 'address' ->> 'locality' AS locality,
        releases -> 'buyer' -> 'address' ->> 'region' AS region,
        releases -> 'buyer' -> 'address' ->> 'postalCode' AS postcode,
        t.json -> 'releases' -> 0 -> 'buyer' -> 'address' ->> 'countryName' AS countryname,
        releases -> 'buyer' -> 'contactPoint' ->> 'name' AS contactName,
        releases -> 'buyer' -> 'contactPoint' ->> 'email' AS email,
        releases -> 'buyer' -> 'contactPoint' ->> 'telephone' AS telephone,
        releases -> 'buyer' -> 'contactPoint' ->> 'faxNumber' AS faxNumber,
        releases -> 'buyer' -> 'contactPoint' ->> 'url' AS contact_url,
        url_doc.value ->> 'url' as tender_url,
        ARRAY(select array_to_string(regexp_matches(releases -> 'tender' #>> '{"items", 0}', '"(\d{8})+"', 'g'), '')) as cpvs,
        t.date_created,
        t.date_updated,
        t.json
       FROM
         ocds.ocds_tenders t,
         LATERAL jsonb_array_elements(t.json -> 'releases') releases
         LEFT JOIN LATERAL jsonb_array_elements(releases -> 'tender' -> 'documents') url_doc(value) ON url_doc.value ->> 'id' = 'tender_url'
        WHERE t.json -> 'releases' -> 0 -> 'tag'='["tender"]'

    ) sub
WHERE
    jsonb_array_length(json -> 'releases') = 1
;
