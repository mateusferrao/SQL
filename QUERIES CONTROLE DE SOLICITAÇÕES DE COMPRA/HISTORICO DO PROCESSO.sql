SELECTTAR.IDINSTTAR ,    T.IDELEMENTO,    T.NOME,    (TAR.DHCRIACAO) AS DHCRIACAO,    (TAR.DHCONCLUSAO) AS DHCONCLUSAO,    (TAR.DHACEITE) AS DHACEITE,        ISNULL(DATEDIFF(HOUR , (TAR.DHCRIACAO) , (ISNULL(TAR.DHCONCLUSAO, GETDATE()))), 0) AS DURACAO,    TAR.CODUSUDONO,    USU.NOMEUSU,    TAR.AD_ULTIMAALTER,    TAR.AD_CODUSUACAO,    USU2.NOMEUSU AS USUALTER,    TAR.AD_DHACAOFROM TWFITAR TARINNER JOIN TWFITAR_ELEMENTO T ON T.IDINSTPRN = TAR.IDINSTPRN AND T.IDINSTTAR = TAR.IDINSTTARINNER JOIN cmd_act_hi_actinst C ON (C.TASK_ID_ = TAR.IDINSTTAR)LEFT JOIN TSIUSU USU ON (TAR.CODUSUDONO = USU.CODUSU)LEFT JOIN TSIUSU USU2 ON (TAR.AD_CODUSUACAO = USU2.CODUSU)WHERE TAR.IDINSTPRN = :IDINSTPRNAND (C.ACT_TYPE_ LIKE 'userTask')ORDER BY TAR.DHCRIACAO ASC