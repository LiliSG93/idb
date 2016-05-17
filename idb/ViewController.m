//
//  ViewController.m
//  idb
//
//  Created by yoyis on 3/17/16.
//  Copyright (c) 2016 yoyis. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    NSMutableArray *arreglopersonas;
    sqlite3 *dbpersonas;
    NSString *dbruta;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    arreglopersonas = [[NSMutableArray alloc]init];
    [[self uilista]setDelegate:self];

    [[self uilista]setDataSource:self];
    [self creaOabredb];
    //poner una imagen en el background
    self.view.backgroundColor= [UIColor colorWithPatternImage:[UIImage imageNamed:@"11.jpg"]];
    _uilista.backgroundColor= [UIColor colorWithPatternImage:[UIImage imageNamed:@"2.jpg"]];
}
//crear la base de datos
-(void)creaOabredb
{
    NSArray *ruta = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *rutadoc = [ruta objectAtIndex:0];
    
    dbruta = [rutadoc stringByAppendingPathComponent:@"personas.db"];
    
    char *error;
    
    NSFileManager *filemanager = [NSFileManager defaultManager];
    if (![filemanager fileExistsAtPath:dbruta]) {
        const char *rutadb = [dbruta UTF8String];
        if (sqlite3_open(rutadb, &dbpersonas)==SQLITE_OK) {
            const char *sql_stmt = "CREATE TABLE IF NOT EXISTS PERSONS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT, LASTNAME TEXT, GROWP INTEGER)";
            sqlite3_exec(dbpersonas, sql_stmt, NULL, NULL, &error);
            sqlite3_close(dbpersonas);// fin de la BD
        }
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [arreglopersonas count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellidentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellidentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellidentifier];
    }
    
    persona *apersona = [arreglopersonas objectAtIndex:indexPath.row];
    
    NSLog(@"%@",apersona.name);
    cell.textLabel.text = [NSString stringWithFormat: @"%@ %@", apersona.name,apersona.lastName];

    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d",apersona.growp];
    
    //agregar la misma imagen a cada usuario de la base de datos
    cell.imageView.image = [UIImage imageNamed:@"apple.png"];
    
    return cell;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)agrega:(id)sender {
    char *error;
 
    if (sqlite3_open([dbruta UTF8String], &dbpersonas)==SQLITE_OK) {
        NSString *inserstmt = [NSString stringWithFormat:@"INSERT INTO PERSONS(NAME,LASTNAME,GROWP) values ('%s', '%s','%d')",[self.uinombre.text UTF8String],[self.uiapellidos.text UTF8String],[self.uigrupo.text intValue]];
        const char *insert_stmt = [inserstmt UTF8String];
        if (sqlite3_exec(dbpersonas, insert_stmt, NULL, NULL, &error)==SQLITE_OK) {
            NSLog(@"Persona agregada");
            
            persona *person = [[persona alloc]init];
            [person setName:self.uinombre.text];
            [person setLastName:self.uiapellidos.text];
            [person setGrowp:[self.uigrupo.text intValue]];
            
            [arreglopersonas addObject:person];
        }
        sqlite3_close(dbpersonas); 
    }
}


- (IBAction)lista:(id)sender {
    
    sqlite3_stmt *statement;
    
    if (sqlite3_open([dbruta UTF8String], &dbpersonas)==SQLITE_OK) {
        
        [arreglopersonas removeAllObjects];
        
        NSString *querySql = [NSString stringWithFormat:@"SELECT * FROM PERSONS"];
        
        const char *query_sql = [querySql UTF8String];
        if (sqlite3_prepare(dbpersonas, query_sql, -1, &statement, NULL)==SQLITE_OK) {
            while (sqlite3_step(statement)==SQLITE_ROW) {
                NSString *nombre_str = [[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
                NSString *lastName_str = [[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 2)];
                NSString *group_str = [[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 3)];
                
                persona *person = [[persona alloc]init];
                
                [person setName:nombre_str];
                [person setLastName:lastName_str];
                [person setGrowp:[group_str intValue]];
                
                [arreglopersonas addObject:person];

            }
        }
        
    }
    
    [[self uilista]reloadData];

}
- (IBAction)elimina:(id)sender {
    //desplazar hacia un lado y eliminar
    [[self uilista] setEditing:!self.uilista.editing animated:YES];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    char *error;
    
    if(editingStyle == UITableViewCellEditingStyleDelete){
        persona *p= [arreglopersonas objectAtIndex:indexPath.row];
        if(sqlite3_open([dbruta UTF8String], &dbpersonas )== SQLITE_OK){
            NSString *deleteQuery=[NSString stringWithFormat:@"DELETE FROM PERSONS WHERE LASTNAME='%s';",[p.lastName UTF8String]];
            const char *deleteBD= [deleteQuery UTF8String];
            if(sqlite3_exec(dbpersonas, deleteBD, NULL, NULL, &error)==SQLITE_OK){
                NSLog(@"Persona eliminada de la Base de Datos");
            }
            sqlite3_close(dbpersonas);
        }
        [arreglopersonas removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [self buscar:[NSString stringWithFormat:@"SELECT * FROM PERSONS WHERE LASTNAME LIKE '%%%@%%';", searchText]];
}
-(void)buscar:(NSString *)buscarSQL {
    sqlite3_stmt *statement;
    persona *person=nil;
    NSLog(@"%@", buscarSQL);
    
    if(sqlite3_open([dbruta UTF8String], &dbpersonas)==SQLITE_OK){
        [arreglopersonas removeAllObjects];
        
        if(sqlite3_prepare(dbpersonas, [[NSString stringWithFormat:@"%@",buscarSQL] UTF8String], -1, &statement, NULL)==SQLITE_OK){
            while(sqlite3_step(statement)==SQLITE_ROW){
                person=[[persona alloc] init];
                [person setName:[[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 1)]];
                [person setLastName:[[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 2)]];
                [person setGrowp:[[[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 3)]intValue]];
                
                [arreglopersonas addObject:person];
                
            }
        }
    }
    [[self uilista]reloadData];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
    [[self uinombre]resignFirstResponder];
    [[self uiapellidos]resignFirstResponder];
    [[self uigrupo]resignFirstResponder];
}

@end
