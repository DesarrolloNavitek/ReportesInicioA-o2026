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
			Pedidos		float
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



SELECT	a.Gerente,
		c.Nombre,
		a.AgenteCliente,
		a.NombreAgente,
		a.Cliente,
		a.NombreCliente,
		ROUND(Ventas,4) AS VentaNeta, 
		TFActuras AS TotalFacturas, 
		ROUND((Ventas/TFActuras),4) AS Factor
  FROM @Ventas			a
  JOIN @TotalF			b	ON a.Cliente=b.Cliente
  JOIN Agente			c	ON a.Gerente = c.Agente
 ORDER BY Factor ASC

 --EXEC xpVentasaClientesAnual

--INSERT INTO @Pedidos

--SELECT Cliente,
--		COUNT(MovID)
--  FROM Venta		v
--  JOIN MovTipo		mt		ON Modulo ='VTAS' AND v.Mov=mt.Mov
-- WHERE Estatus = 'CONCLUIDO'
--   AND v.Mov <> 'Cotizacion'
--   AND YEAR(v.FechaEmision) = 2025
--   and Clave = 'VTAS.P' 
--   and SubClave = 'VTAS.PNVK'
--  GROUP BY v.Cliente
-- ORDER BY v.Cliente

--SELECT a.Cliente+' - '+Nombre AS NombreClinte,
--		Ventas,
--		TFActuras AS TotalFacturacion,
--		Factor
--  FROM @Ventas			a
--  LEFT JOIN @Pedidos			b		ON a.Cliente=b.Cliente
--  ORDER BY Factor ASC
RETURN
END
--select * from MovTipo where Modulo ='VTAS' and Clave = 'VTAS.P' and SubClave = 'VTAS.PNVK'

--select distinct (mov) from nvk_vw_IngresosNetos_Detalle