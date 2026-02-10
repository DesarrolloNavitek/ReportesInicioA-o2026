/*Ventas año por cliente*/
SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF;
--EXEC xpComparativoVentas
IF EXISTS (SELECT 1 FROM Sys.procedures WHERE name = 'xpComparativoVentas')
DROP PROCEDURE xpComparativoVentas
GO
CREATE PROCEDURE xpComparativoVentas
AS
BEGIN

DECLARE 
@EjercicioD     datetime ,
@EjercicioA     datetime = GETDATE()

SET @EjercicioD = (YEAR(@EjercicioA)-4)
SET @EjercicioA = (YEAR(@EjercicioA)-1)


;WITH TotalVentasAnt AS (
        SELECT DISTINCT Cliente,
                NombreCliente,
                YEAR(FechaEmision) AS Ejercicio,
                CASE WHEN YEAR(FechaEmision) = @EjercicioD THEN (SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)) 
                     
                     ELSE 0 END AS VentasTotalesAnt
        FROM NVK_VW_HistVtaCte_2021_Hoy
       WHERE YEAR(FechaEmision) IN (@EjercicioD)
       GROUP BY Cliente,NombreCliente,YEAR(FechaEmision)
),
VentasAnualesAnt AS (
    SELECT *, 
        ROW_NUMBER() OVER (PARTITION BY Ejercicio ORDER BY VentasTotalesAnt DESC) AS Ranking
    FROM TotalVentasAnt
    GROUP BY Cliente,NombreCliente,Ejercicio,VentasTotalesAnt
    HAVING SUM(VentasTotalesAnt) > 0
)
,
TotalVentasAct AS (
        SELECT Cliente,
                YEAR(FechaEmision) AS Ejercicio,
                CASE --WHEN YEAR(FechaEmision) = 2022 THEN (SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)) 
                     WHEN YEAR(FechaEmision) = 2025 THEN (SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)) 
                     ELSE 0 END AS VentasTotalesAct
        FROM NVK_VW_HistVtaCte_2021_Hoy
       WHERE YEAR(FechaEmision) IN (@EjercicioA)
       GROUP BY Cliente,YEAR(FechaEmision)
)
,
Comparacion AS (
    SELECT 
        v1.Cliente,
        v1.NombreCliente,
        ROUND(COALESCE(v1.VentasTotalesAnt,0),4) AS 'VentasAnteriores',
        ROUND(COALESCE(v2.VentasTotalesAct,0),4) AS 'VentasActuales',
        v1.Ranking,
        (ROUND(COALESCE(v2.VentasTotalesAct,0),4) - ROUND(COALESCE(v1.VentasTotalesAnt,0),4)) AS Variacion
        --CASE 
        --    WHEN COALESCE(v2.VentasTotalesAct,0) = 0 THEN -100
        --    ELSE  ((ROUND(COALESCE(v2.VentasTotalesAct,0),4) / ROUND(COALESCE(v1.VentasTotalesAnt,0),4)) *100) -100 END AS VariacionPorc
            
          
    FROM VentasAnualesAnt v1
    LEFT JOIN TotalVentasAct v2 ON v1.Cliente = v2.Cliente --AND v2.Ejercicio = v1.Ejercicio - 1
    --WHERE --v1.Ranking <= 30
    --ROUND(COALESCE(v2.VentasTotalesAct,0),4) < ROUND(COALESCE(v1.VentasTotalesAnt,0),4)
    
)
SELECT a.Cliente,
        NombreCliente,
        VentasAnteriores AS '2023',
        VentasActuales AS '2025',
        Variacion
FROM Comparacion        a
LEFT JOIN Cte           b   ON a.Cliente=b.Cliente
WHERE VentasActuales < VentasAnteriores
AND b.Pais NOT IN ('FRANCIA','GUATEMALA','TAIWAN, R.O.C.','EL SALVADOR','ITALIA','ALEMANIA',
'HONDURAS',
'NICARAGUA',
'CHINA',
--'',
'CANADA',
'Canadá',
'VENEZUELA',
'COLOMBIA',
'PANAMA',
'Estados Unidos (los)',
'PORTUGAL',
'COSTA RICA')
--AND VariacionPorc between -100 AND 100
ORDER BY Variacion --WHERE VariacionPorc >= 100 

RETURN
END