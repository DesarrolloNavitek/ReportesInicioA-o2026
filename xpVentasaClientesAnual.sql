/*Ventas año por cliente*/
SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF;
--EXEC xpVentasaClientesAnual
IF EXISTS (SELECT 1 FROM Sys.procedures WHERE name = 'xpVentasaClientesAnual')
DROP PROCEDURE xpVentasaClientesAnual
GO
CREATE PROCEDURE xpVentasaClientesAnual
AS
BEGIN
DECLARE
@Ejercicio	int =	YEAR(GETDATE())


DECLARE		@Ventas		TABLE	(
			Cliente				varchar(10),
			NombreCliente		varchar(100),
			Ventas				money,
			AgenteCliente		varchar(10),
			NombreAgente		varchar(100),
			Gerente				varchar(10)

)


DECLARE		@TotalF		TABLE	(
			Cliente		varchar(10),
			TFActuras		int
)

DECLARE		@Pedidos	TABLE (
			Cliente		varchar(10),
			Pedidos		int
)


SET @Ejercicio = (@Ejercicio-1)

DELETE FROM nvk_tb_ExpIngresoNeto_Imp WHERE SPID = @@SPID


INSERT INTO @Ventas

SELECT v.Cliente,
		v.NombreCliente,
		(SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)),
		v.AgenteCliente,
		MAX(a.Nombre),
		CASE WHEN COALESCE(a.ReportaA,'') = '' THEN v.AgenteCliente ELSE ReportaA END
 FROM nvk_vw_VentasNetas_Detalle_Cliente	v
 LEFT JOIN Agente							a			ON	v.AgenteCliente=a.Agente
 JOIN Cte 									b			ON v.Cliente=b.cliente AND b.Estatus = 'ALTA'
WHERE v.Estatus IN ('CONCLUIDO')
  AND v.Mov NOT IN ('Factura Activo Fijo')
  AND YEAR(v.FechaEmision) = @Ejercicio
GROUP BY v.Cliente,v.NombreCliente,v.AgenteCliente,a.ReportaA
ORDER BY v.Cliente



INSERT INTO @TotalF

SELECT v.Cliente,
COUNT(DISTINCT v.MovID)
 FROM nvk_vw_VentasNetas_Detalle_Cliente	v
WHERE v.Estatus IN ('CONCLUIDO')
  AND v.MovTipo IN ('VTAS.F','VTAS.FB')
  AND v.Mov NOT IN ('Factura Activo Fijo')
  AND YEAR(v.FechaEmision) = @Ejercicio
GROUP BY v.Cliente


INSERT INTO @Pedidos

SELECT v.Cliente,
COUNT(DISTINCT v.MovID)
 FROM Venta		v
 JOIN MovTipo	mt ON v.Mov=mt.Mov AND mt.Modulo ='VTAS' AND mt.Clave = 'VTAS.P'
 LEFT JOIN	MovFlujo  mf	ON mf.OID=v.ID and OModulo ='VTAS' and DModulo = 'VTAS' and DMov = 'Factura' and Cancelado = 0
WHERE v.Estatus IN ('CONCLUIDO')
  AND v.Mov NOT IN ('Cotizacion')
  AND YEAR(v.FechaEmision) = @Ejercicio
  AND mt.SubClave = 'VTAS.PNVK'
  --AND v.Cliente = '5236'
  AND mf.OID IS NOT NULL
GROUP BY v.Cliente
  UNION
  ALL
SELECT v.Cliente,
COUNT(DISTINCT v.MovID)
 FROM Venta		v
 JOIN MovTipo	mt ON v.Mov=mt.Mov AND mt.Modulo ='VTAS' AND mt.Clave = 'VTAS.P'
 LEFT JOIN	MovFlujo  mf	ON mf.OID=v.ID and OModulo ='VTAS' and DModulo = 'VTAS' and DMov like '%Fatura%' and Cancelado = 0
WHERE v.Estatus IN ('CONCLUIDO')
  AND v.Mov NOT IN ('Cotizacion')
  AND YEAR(v.FechaEmision) = @Ejercicio
  AND mt.SubClave IN ('VTAS.EXPORT')
  --AND v.Cliente = '11208'
  --OR mf.OID IS NOT NULL
GROUP BY v.Cliente


--SELECT v.Cliente,
--COUNT(DISTINCT v.MovID)
-- FROM Venta		v
-- JOIN MovTipo	mt ON v.Mov=mt.Mov AND mt.Modulo ='VTAS' --AND mt.Clave = 'VTAS.P'
-- LEFT JOIN	MovFlujo  mf	ON mf.OID=v.ID and OModulo ='VTAS' and DModulo = 'VTAS' and DMov = 'FActura' and Cancelado = 0
--WHERE v.Estatus IN ('CONCLUIDO')
--  AND v.Mov NOT IN ('Cotizacion')
--  AND YEAR(v.FechaEmision) = @Ejercicio
--  AND mt.SubClave = 'VTAS.PNVK'
--  --AND v.Cliente = '5236'
--  AND mf.OID IS NOT NULL
--GROUP BY v.Cliente

SELECT	a.Gerente,
		c.Nombre,
		a.AgenteCliente,
		a.NombreAgente,
		a.Cliente,
		a.NombreCliente,
		ROUND(Ventas,4) AS VentaNeta, 
		TFActuras AS TotalFacturas,
		COALESCE(Pedidos,0) AS Pedidos,
		ROUND((Ventas/TFActuras),4) AS Factor
  FROM @Ventas			a
  LEFT JOIN @TotalF			b	ON a.Cliente=b.Cliente
  LEFT JOIN @Pedidos			d	ON a.Cliente=d.Cliente
  JOIN Agente			c	ON a.Gerente = c.Agente
 WHERE Ventas > 0
 ORDER BY Factor ASC

 --EXEC xpVentasaClientesAnual


RETURN
END
